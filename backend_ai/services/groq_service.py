import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Type, TypeVar
from groq import Groq, GroqError, APIConnectionError, RateLimitError, APIStatusError
from pydantic import BaseModel

from config.settings import settings
from utils.json_utils import parse_json_safely
from utils.logger import get_logger

logger = get_logger("groq_service")
T = TypeVar("T", bound=BaseModel)

# Active, ultra-fast Groq LLM models (<250ms completion time)
FALLBACK_MODELS: List[str] = [
    "openai/gpt-oss-120b",        # Primary 120B: deep reasoning & high intelligence
    "openai/gpt-oss-20b",         # Ultra-fast 20B (<150ms)
    "qwen/qwen3.6-27b",           # 27B high-precision fallback
    "groq/compound",              # Robust compound model
]

MAX_PROMPT_CHARS = 4500  # Safe limit to keep requests well under Groq 6000 TPM limit


class GroqService:
    """Centralized service for interacting with the Groq API (LLM & Audio Whisper STT) with automatic model fallback."""

    def __init__(self, api_key: Optional[str] = None, model: Optional[str] = None):
        self.api_key = settings.GROQ_API_KEY if api_key is None else api_key
        self.primary_model = model or settings.GROQ_MODEL
        self.client: Optional[Groq] = None

        if self.api_key:
            try:
                self.client = Groq(api_key=self.api_key, timeout=15.0)
            except Exception as e:
                logger.error(f"Failed to initialize Groq client: {e}")

    def is_configured(self) -> bool:
        """Checks whether the Groq API client is ready to use."""
        return (
            self.client is not None
            and bool(self.api_key)
            and self.api_key.strip() != "your_groq_api_key_here"
            and not self.api_key.startswith("your_")
        )

    def _truncate_prompt(self, prompt: str) -> str:
        """Ensures prompt does not exceed maximum character safety limits."""
        if len(prompt) > MAX_PROMPT_CHARS:
            logger.info(f"Truncating long prompt from {len(prompt)} to {MAX_PROMPT_CHARS} characters for token safety.")
            return prompt[:MAX_PROMPT_CHARS] + "\n...[truncated for token safety]"
        return prompt

    def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.5,
        max_tokens: int = 1500,
        model: Optional[str] = None,
    ) -> str:
        """Generates text response from Groq LLM with automatic model fallback cascade on rate limits."""
        if not self.is_configured():
            raise ValueError("Groq API Key is missing. Please set GROQ_API_KEY in your environment or .env file.")

        safe_prompt = self._truncate_prompt(prompt)
        models_to_try = [model or self.primary_model] + [m for m in FALLBACK_MODELS if m != (model or self.primary_model)]
        messages = []

        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": safe_prompt})

        last_error = None
        for current_model in models_to_try:
            attempts = 0
            max_attempts = 2

            while attempts < max_attempts:
                try:
                    attempts += 1
                    logger.debug(f"Sending Groq request using model '{current_model}' (Attempt {attempts})")

                    response = self.client.chat.completions.create(
                        model=current_model,
                        messages=messages,
                        temperature=temperature,
                        max_tokens=max_tokens,
                    )

                    content = response.choices[0].message.content
                    if content:
                        return content.strip()
                    return ""

                except RateLimitError as e:
                    logger.warning(f"Groq Rate Limit on model '{current_model}'. Retrying in 0.1s...")
                    time.sleep(0.1)
                    last_error = e
                except APIConnectionError as e:
                    logger.warning(f"Groq Connection Error on '{current_model}' (Attempt {attempts}): {e}")
                    last_error = e
                    if attempts < max_attempts:
                        time.sleep(0.1)
                except APIStatusError as e:
                    if e.status_code in [429, 413]:
                        logger.warning(f"Groq {e.status_code} Error on model '{current_model}'. Retrying in 0.1s...")
                        time.sleep(0.1)
                        last_error = e
                        break
                    logger.error(f"Groq API Status Error on '{current_model}': {e}")
                    last_error = e
                    break
                except Exception as e:
                    logger.error(f"Error calling model '{current_model}': {e}")
                    last_error = e
                    break

        if last_error:
            raise last_error
        return ""

    def generate_json(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.2,
        max_tokens: int = 3500,
        model: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Generates structured JSON response from Groq LLM with fallback cascade across active models."""
        if not self.is_configured():
            logger.warning("Groq API Key is unconfigured or placeholder. Using fallback JSON engine.")
            return None

        safe_prompt = self._truncate_prompt(prompt)
        models_to_try = [model or self.primary_model] + [m for m in FALLBACK_MODELS if m != (model or self.primary_model)]
        formatted_system = (system_prompt or "") + "\n\nCRITICAL: Respond ONLY with valid JSON. Do not include markdown formatting or conversational text."

        for current_model in models_to_try:
            messages = [
                {"role": "system", "content": formatted_system.strip()},
                {"role": "user", "content": safe_prompt},
            ]
            try:
                response = self.client.chat.completions.create(
                    model=current_model,
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens,
                    response_format={"type": "json_object"},
                )
                raw_content = response.choices[0].message.content or ""
                parsed = parse_json_safely(raw_content)
                if parsed:
                    return parsed
            except RateLimitError:
                logger.warning(f"Groq Rate Limit (429) on model '{current_model}'. Waiting 1.0s for token reset...")
                time.sleep(1.0)
                continue
            except Exception as e:
                logger.warning(f"JSON completion failed on model '{current_model}': {e}. Trying fallback...")
                time.sleep(0.5)
                continue

        # Final attempt via plain generate fallback
        raw_content = self.generate(
            prompt=safe_prompt,
            system_prompt=formatted_system,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        return parse_json_safely(raw_content)

    def generate_structured(
        self,
        model_class: Type[T],
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.2,
        max_tokens: int = 3500,
    ) -> Optional[T]:
        """Generates and validates response into a Pydantic model."""
        json_data = self.generate_json(
            prompt=prompt,
            system_prompt=system_prompt,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        if json_data is None:
            return None
        try:
            return model_class.model_validate(json_data)
        except Exception as e:
            logger.error(f"Validation error for {model_class.__name__}: {e}")
            return None

    def transcribe_audio(self, audio_file_path: Path, model: str = "whisper-large-v3-turbo") -> str:
        """Transcribes audio file using Groq's high-speed Whisper API."""
        if not self.is_configured():
            raise ValueError("Groq API Key is missing. Please set GROQ_API_KEY in your environment or .env file.")

        path = Path(audio_file_path)
        if not path.exists():
            logger.error(f"Audio file not found for transcription: {path}")
            return ""

        try:
            logger.info(f"Transcribing audio file ({path.stat().st_size} bytes) via Groq Whisper API ({model})...")
            with open(path, "rb") as audio_file:
                transcription = self.client.audio.transcriptions.create(
                    file=(path.name, audio_file.read()),
                    model=model,
                    response_format="text",
                )
            if isinstance(transcription, str):
                return transcription.strip()
            elif hasattr(transcription, "text"):
                return transcription.text.strip()
            return str(transcription).strip()
        except Exception as e:
            logger.error(f"Error transcribing audio via Groq Whisper API: {e}")
            return ""

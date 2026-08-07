import json
import re
from typing import Any, Dict, Optional, Type, TypeVar
from pydantic import BaseModel
from utils.logger import get_logger

logger = get_logger("json_utils")
T = TypeVar("T", bound=BaseModel)


def clean_json_string(raw_response: str) -> str:
    """Strips markdown code blocks and returns cleaned JSON string."""
    text = raw_response.strip()

    # Pattern for ```json ... ``` or ``` ... ```
    match = re.search(r"```(?:json)?\s*(.*?)\s*```", text, re.DOTALL | re.IGNORECASE)
    if match:
        return match.group(1).strip()

    # If no markdown blocks, find outer braces or brackets
    start_brace = text.find("{")
    end_brace = text.rfind("}")
    if start_brace != -1 and end_brace != -1 and end_brace > start_brace:
        return text[start_brace : end_brace + 1].strip()

    return text


def parse_json_safely(raw_response: str) -> Optional[Dict[str, Any]]:
    """Attempts to parse raw LLM text output into a Python dictionary."""
    cleaned = clean_json_string(raw_response)
    try:
        data = json.loads(cleaned)
        if isinstance(data, dict):
            return data
        logger.warning(f"Parsed JSON is not a dictionary: {type(data)}")
        return None
    except json.JSONDecodeError as e:
        logger.error(f"Failed to decode JSON from LLM response: {e}. Raw response excerpt: {raw_response[:200]}")
        return None


def parse_pydantic_safely(model_class: Type[T], raw_response: str) -> Optional[T]:
    """Parses raw text response into a Pydantic model instance safely."""
    data = parse_json_safely(raw_response)
    if data is None:
        return None
    try:
        return model_class.model_validate(data)
    except Exception as e:
        logger.error(f"Failed to validate Pydantic model {model_class.__name__}: {e}")
        return None

import os
import sys
import time
import asyncio
from pathlib import Path
from typing import Optional

try:
    import sounddevice as sd
    import scipy.io.wavfile as wav
    HAS_AUDIO_RECORDER = True
except Exception:
    HAS_AUDIO_RECORDER = False

try:
    import pyttsx3
    HAS_PYTTSX3 = True
except Exception:
    HAS_PYTTSX3 = False

try:
    import edge_tts
    HAS_EDGE_TTS = True
except Exception:
    HAS_EDGE_TTS = False

try:
    import pygame
    HAS_PYGAME = True
    pygame.mixer.init()
except Exception:
    HAS_PYGAME = False

from config.settings import settings
from services.groq_service import GroqService
from utils.logger import get_logger

logger = get_logger("voice_service")

# Map of human-friendly persona names to Edge-TTS Neural Voice IDs
NEURAL_VOICES = {
    "guy": "en-US-GuyNeural",               # Senior Male Tech Lead (Default)
    "christopher": "en-US-ChristopherNeural", # Executive Tech Director
    "aria": "en-US-AriaNeural",             # Senior Female Engineering Lead
    "ryan": "en-GB-RyanNeural",             # British Engineering Director
}


class VoiceService:
    """Service handling microphone recording, Groq Whisper STT, and Edge-TTS Neural speech synthesis."""

    def __init__(self, groq_service: Optional[GroqService] = None, voice_persona: str = "guy"):
        self.groq_service = groq_service or GroqService()
        self.voice_id = NEURAL_VOICES.get(voice_persona.lower(), NEURAL_VOICES["guy"])

    def set_voice_persona(self, voice_persona: str) -> None:
        """Sets the active Microsoft Edge Neural Voice ID."""
        self.voice_id = NEURAL_VOICES.get(voice_persona.lower(), NEURAL_VOICES["guy"])
        logger.info(f"Set Voice Service persona to: {self.voice_id}")

    def speak(self, text: str) -> None:
        """Speaks text aloud using Microsoft Edge Neural Voice (falling back to pyttsx3 offline if needed)."""
        if not text or not text.strip():
            return

        clean_text = text.strip()
        logger.info(f"Speaking text aloud using Edge-TTS Neural Voice ({self.voice_id})...")

        # 1. Primary: Edge-TTS Neural Voice + Pygame playback
        if HAS_EDGE_TTS and HAS_PYGAME:
            try:
                asyncio.run(self._speak_edge_tts(clean_text))
                return
            except Exception as e:
                logger.warning(f"Edge-TTS synthesis failed: {e}. Falling back to pyttsx3...")

        # 2. Fallback: Local offline pyttsx3 engine
        if HAS_PYTTSX3:
            try:
                engine = pyttsx3.init()
                engine.setProperty("rate", 200) # Standard 1.0x natural speech rate (200 wpm)
                engine.setProperty("volume", 1.0)
                engine.say(clean_text)
                engine.runAndWait()
                engine.stop()
            except Exception as e:
                logger.error(f"Offline pyttsx3 TTS failed: {e}")
        else:
            logger.warning("No TTS engine available for playback.")

    async def _speak_edge_tts(self, text: str) -> None:
        """Asynchronous generator that communicates with Microsoft Edge Neural TTS and plays audio via Pygame."""
        temp_dir = settings.DATA_DIR / "temp"
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_mp3_path = temp_dir / "edge_tts_speech.mp3"

        communicate = edge_tts.Communicate(text, self.voice_id)
        await communicate.save(str(temp_mp3_path))

        # Play audio using pygame.mixer
        pygame.mixer.music.load(str(temp_mp3_path))
        pygame.mixer.music.play()
        while pygame.mixer.music.get_busy():
            await asyncio.sleep(0.1)

        # Unload music file to release handle
        pygame.mixer.music.unload()

    def record_microphone_audio(self, duration_seconds: int = 60, sample_rate: int = 16000) -> Optional[Path]:
        """Records microphone audio and saves it as a temporary WAV file."""
        if not HAS_AUDIO_RECORDER:
            logger.error("Microphone recording dependencies (sounddevice/scipy) are missing.")
            return None

        temp_dir = settings.DATA_DIR / "temp"
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_wav_path = temp_dir / "candidate_mic_input.wav"

        logger.info(f"Recording microphone for up to {duration_seconds} seconds...")
        print(f"\n🎙️  Recording audio... (Speaking for up to {duration_seconds}s)")

        try:
            recording = sd.rec(
                int(duration_seconds * sample_rate),
                samplerate=sample_rate,
                channels=1,
                dtype="int16",
            )

            print("    [Press ENTER to finish recording early]")
            sys.stdout.flush()

            start_time = time.time()
            while time.time() - start_time < duration_seconds:
                if sys.stdin in select_file_descriptors():
                    sys.stdin.readline()
                    sd.stop()
                    break
                time.sleep(0.1)

            sd.wait()
            wav.write(str(temp_wav_path), sample_rate, recording)
            logger.info(f"Microphone recording saved to {temp_wav_path}")
            return temp_wav_path

        except Exception as e:
            logger.error(f"Error capturing audio from microphone: {e}")
            return None

    def record_and_transcribe(self, duration_seconds: int = 60) -> str:
        """Captures microphone input and transcribes it via Groq Whisper API."""
        wav_path = self.record_microphone_audio(duration_seconds=duration_seconds)
        if not wav_path or not wav_path.exists():
            return ""

        print("⚡ Transcribing audio via Groq Whisper AI...")
        transcription = self.groq_service.transcribe_audio(wav_path)
        logger.info(f"Groq Whisper transcribed text: '{transcription}'")
        return transcription

    def analyze_speech_analytics(self, transcript: str, duration_sec: float = 15.0) -> dict:
        """Analyzes transcript for WPM, filler words count, and clarity score."""
        if not transcript:
            return {"wpm": 0, "filler_count": 0, "clarity_score": 75}
        
        words = transcript.split()
        word_count = len(words)
        wpm = int((word_count / max(duration_sec, 1.0)) * 60)
        wpm = max(60, min(wpm, 240))

        filler_words = ["uh", "um", "like", "you know", "basically", "literally", "actually", "so", "right"]
        filler_count = sum(transcript.lower().count(fw) for fw in filler_words)
        clarity_score = max(40, min(100, 85 - (filler_count * 3) + min(word_count // 10, 15)))

        return {
            "wpm": wpm,
            "filler_count": filler_count,
            "clarity_score": clarity_score,
        }

    def analyze_speech_analytics(self, transcript: str, duration_sec: float = 15.0) -> dict:
        """Analyzes transcript for WPM, filler words count, and clarity score."""
        if not transcript:
            return {"wpm": 0, "filler_count": 0, "clarity_score": 75}
        
        words = transcript.split()
        word_count = len(words)
        wpm = int((word_count / max(duration_sec, 1.0)) * 60)
        wpm = max(60, min(wpm, 240))

        filler_words = ["uh", "um", "like", "you know", "basically", "literally", "actually", "so", "right"]
        filler_count = sum(transcript.lower().count(fw) for fw in filler_words)
        clarity_score = max(40, min(100, 85 - (filler_count * 3) + min(word_count // 10, 15)))

        return {
            "wpm": wpm,
            "filler_count": filler_count,
            "clarity_score": clarity_score,
        }


def select_file_descriptors():
    """Cross-platform helper to check if stdin has pending input without blocking."""
    try:
        import msvcrt
        return [sys.stdin] if msvcrt.kbhit() else []
    except ImportError:
        import select
        return select.select([sys.stdin], [], [], 0)[0]

import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file if present
BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


class Settings:
    """Central configuration class for the AI Interviewer application."""

    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    # Default to openai/gpt-oss-120b for top-tier 120B parameter interview intelligence
    GROQ_MODEL: str = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b")

    # Directory Paths
    BASE_DIR: Path = BASE_DIR
    DATA_DIR: Path = BASE_DIR / "data"
    REPORTS_DIR: Path = BASE_DIR / os.getenv("REPORT_DIR", "data/reports")
    RESUMES_DIR: Path = BASE_DIR / os.getenv("RESUME_DIR", "data/resumes")

    # LLM Settings
    DEFAULT_TEMPERATURE: float = 0.5
    EVALUATION_TEMPERATURE: float = 0.2
    MAX_RETRIES: int = 3
    REQUEST_TIMEOUT: float = 45.0

    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")

    @classmethod
    def validate(cls) -> bool:
        """Validates critical settings."""
        if not cls.GROQ_API_KEY:
            return False
        return True

    @classmethod
    def ensure_directories(cls) -> None:
        """Ensures all necessary local directories exist."""
        cls.DATA_DIR.mkdir(parents=True, exist_ok=True)
        cls.REPORTS_DIR.mkdir(parents=True, exist_ok=True)
        cls.RESUMES_DIR.mkdir(parents=True, exist_ok=True)


settings = Settings()
settings.ensure_directories()

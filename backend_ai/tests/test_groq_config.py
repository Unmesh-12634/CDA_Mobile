import pytest
from config.settings import Settings
from services.groq_service import GroqService


def test_groq_missing_api_key():
    """Tests that GroqService properly reports unconfigured state when API key is missing."""
    service = GroqService(api_key="")
    assert service.is_configured() is False
    with pytest.raises(ValueError, match="Groq API Key is missing"):
        service.generate("Hello")


def test_groq_configured():
    """Tests that GroqService reports configured state when API key is present."""
    service = GroqService(api_key="gsk_test_mock_key")
    assert service.is_configured() is True

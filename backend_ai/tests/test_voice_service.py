from unittest.mock import MagicMock
from services.voice_service import VoiceService


def test_voice_service_initialization():
    mock_groq = MagicMock()
    service = VoiceService(groq_service=mock_groq)
    assert service.groq_service == mock_groq


def test_voice_transcribe_audio():
    mock_groq = MagicMock()
    mock_groq.transcribe_audio.return_value = "I built a microservices architecture using Spring Boot."

    service = VoiceService(groq_service=mock_groq)
    result = service.groq_service.transcribe_audio("fake_path.wav")

    assert result == "I built a microservices architecture using Spring Boot."

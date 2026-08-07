from typing import Optional
from models.candidate import CandidateProfile
from prompts.resume_prompt import RESUME_EXTRACTION_SYSTEM_PROMPT, RESUME_EXTRACTION_USER_PROMPT
from services.groq_service import GroqService
from utils.file_utils import parse_resume_file
from utils.logger import get_logger

logger = get_logger("resume_service")


class ResumeService:
    """Service for parsing resume documents and converting them into structured candidate profiles."""

    def __init__(self, groq_service: GroqService):
        self.groq_service = groq_service

    def process_resume(self, file_path: str, candidate_name: str = "Candidate") -> CandidateProfile:
        """Parses a PDF/DOCX resume file into a structured CandidateProfile model."""
        if not file_path or not file_path.strip():
            logger.info("No resume path provided. Initializing baseline candidate profile.")
            return CandidateProfile(name=candidate_name, has_resume=False)

        raw_text = parse_resume_file(file_path)
        if not raw_text:
            logger.warning(f"Unable to extract text from resume path: {file_path}. Using fallback profile.")
            return CandidateProfile(name=candidate_name, has_resume=False)

        # Truncate raw resume text to 3,000 chars (~750 tokens) to ensure prompt stays well below API limits
        safe_resume_text = raw_text[:3000]
        prompt = RESUME_EXTRACTION_USER_PROMPT.format(resume_text=safe_resume_text)

        profile = self.groq_service.generate_structured(
            model_class=CandidateProfile,
            prompt=prompt,
            system_prompt=RESUME_EXTRACTION_SYSTEM_PROMPT,
            temperature=0.1,
        )

        if not profile:
            logger.warning("LLM resume extraction failed. Returning default baseline profile.")
            return CandidateProfile(name=candidate_name, summary=raw_text[:300], has_resume=True)

        if candidate_name and candidate_name != "Candidate":
            profile.name = candidate_name

        profile.has_resume = True
        logger.info(f"Resume parsed successfully for candidate '{profile.name}' with {len(profile.skills)} skills extracted.")
        return profile

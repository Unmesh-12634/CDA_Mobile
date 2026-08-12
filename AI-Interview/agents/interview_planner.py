from typing import Optional
from models.candidate import CandidateProfile
from models.interview import InterviewConfig, InterviewPlan, TopicAllocation
from prompts.planner_prompt import PLANNER_SYSTEM_PROMPT, PLANNER_USER_PROMPT
from services.groq_service import GroqService
from utils.logger import get_logger

logger = get_logger("interview_planner")


class InterviewPlannerAgent:
    """Agent responsible for creating and dynamically adjusting the strategic interview plan."""

    def __init__(self, groq_service: GroqService):
        self.groq_service = groq_service

    def create_plan(self, config: InterviewConfig, profile: CandidateProfile) -> InterviewPlan:
        """Generates a custom strategic interview plan instantly (0ms) based on candidate profile & role requirements."""
        top_skills = profile.skills[:4] if profile.skills else ["Core Fundamentals", "Problem Solving"]
        skills_str = ", ".join(top_skills)

        default_topics = [
            TopicAllocation(
                topic_name=f"Core {config.job_role} Concepts",
                weight_percentage=35.0,
                target_questions=max(1, int(config.target_question_count * 0.35)),
            ),
            TopicAllocation(
                topic_name=f"Hands-on Experience ({skills_str})",
                weight_percentage=30.0,
                target_questions=max(1, int(config.target_question_count * 0.30)),
            ),
            TopicAllocation(
                topic_name="System Architecture & Problem Solving",
                weight_percentage=20.0,
                target_questions=max(1, int(config.target_question_count * 0.20)),
            ),
            TopicAllocation(
                topic_name="Behavioral & Role Readiness",
                weight_percentage=15.0,
                target_questions=max(1, int(config.target_question_count * 0.15)),
            ),
        ]

        return InterviewPlan(
            job_role=config.job_role,
            focus_summary=f"Comprehensive {config.interview_type.value} interview for {config.job_role} ({profile.experience_level}) focusing on {skills_str}.",
            topic_allocations=default_topics,
            key_objectives=[f"Assess core competencies for {config.job_role}"],
        )

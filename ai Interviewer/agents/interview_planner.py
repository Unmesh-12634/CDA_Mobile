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
        """Generates a custom strategic interview plan based on candidate projects, skills, level, and role."""
        prompt = PLANNER_USER_PROMPT.format(
            candidate_detailed_context=profile.to_detailed_prompt_context(),
            job_role=config.job_role,
            interview_type=config.interview_type.value,
            difficulty=config.difficulty.value,
            target_question_count=config.target_question_count,
        )

        plan = self.groq_service.generate_structured(
            model_class=InterviewPlan,
            prompt=prompt,
            system_prompt=PLANNER_SYSTEM_PROMPT,
            temperature=0.3,
        )

        if not plan or not plan.topic_allocations:
            logger.warning("Failed to generate LLM plan. Falling back to default strategic plan.")
            return self._fallback_plan(config, profile)

        return plan

    def _fallback_plan(self, config: InterviewConfig, profile: CandidateProfile) -> InterviewPlan:
        """Generates a reliable fallback plan if LLM output fails."""
        default_topics = [
            TopicAllocation(topic_name=f"Core {config.job_role} Concepts", weight_percentage=35.0, target_questions=3),
            TopicAllocation(topic_name="Project Deep-Dive & Tech Stack", weight_percentage=30.0, target_questions=2),
            TopicAllocation(topic_name="System Architecture & Problem Solving", weight_percentage=20.0, target_questions=2),
            TopicAllocation(topic_name="Behavioral & Role Readiness", weight_percentage=15.0, target_questions=1),
        ]
        return InterviewPlan(
            job_role=config.job_role,
            focus_summary=f"Comprehensive {config.interview_type.value} interview for {config.job_role} ({profile.experience_level}).",
            topic_allocations=default_topics,
            key_objectives=[f"Assess core competencies for {config.job_role}"],
        )

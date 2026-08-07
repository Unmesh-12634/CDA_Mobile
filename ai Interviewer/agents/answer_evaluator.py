from typing import Optional
from models.evaluation import AnswerEvaluation
from models.question import Question
from prompts.evaluation_prompt import EVALUATION_SYSTEM_PROMPT, EVALUATION_USER_PROMPT
from services.groq_service import GroqService
from utils.logger import get_logger

logger = get_logger("answer_evaluator")


class AnswerEvaluatorAgent:
    """Agent responsible for analyzing candidate responses after every turn."""

    def __init__(self, groq_service: GroqService):
        self.groq_service = groq_service

    def evaluate_answer(
        self,
        question: Question,
        candidate_answer: str,
        job_role: str,
    ) -> AnswerEvaluation:
        """Evaluates technical correctness, clarity, depth, and recommended next action."""
        if not candidate_answer or len(candidate_answer.strip()) < 3:
            logger.info(f"Empty or negligible answer received for Question #{question.id}")
            return AnswerEvaluation(
                question_id=question.id,
                technical_accuracy=2.0,
                relevance=2.0,
                clarity=2.0,
                depth=2.0,
                overall=2.0,
                strengths=[],
                missing_points=["No substantive answer provided."],
                follow_up_needed=False,
                recommended_next_action="decrease_difficulty",
                feedback_summary="Candidate provided minimal or no answer.",
            )

        prompt = EVALUATION_USER_PROMPT.format(
            question_id=question.id,
            job_role=job_role,
            topic=question.topic,
            question_type=question.question_type.value,
            question_text=question.text,
            candidate_answer=candidate_answer,
        )

        evaluation = self.groq_service.generate_structured(
            model_class=AnswerEvaluation,
            prompt=prompt,
            system_prompt=EVALUATION_SYSTEM_PROMPT,
            temperature=0.2,
        )

        if not evaluation:
            logger.warning("Failed to evaluate answer via structured LLM output. Using fallback evaluation.")
            return self._fallback_evaluation(question.id)

        evaluation.question_id = question.id
        return evaluation

    def _fallback_evaluation(self, question_id: int) -> AnswerEvaluation:
        """Fallback evaluation object in case of API or parsing issues."""
        return AnswerEvaluation(
            question_id=question_id,
            technical_accuracy=7.0,
            relevance=7.0,
            clarity=7.0,
            depth=6.0,
            overall=6.8,
            strengths=["Answer submitted and recorded."],
            missing_points=[],
            follow_up_needed=False,
            recommended_next_action="next_topic",
            feedback_summary="Standard answer recorded.",
        )

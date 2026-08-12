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
            return self._fallback_evaluation(question.id, candidate_answer, question.topic)

        evaluation.question_id = question.id
        return evaluation

    def _fallback_evaluation(self, question_id: int, candidate_answer: str = "", topic: str = "") -> AnswerEvaluation:
        """Fallback evaluation object in case of API or parsing issues with heuristic score calculation."""
        text = candidate_answer.lower().strip()
        words = text.split()
        word_count = len(words)

        dont_know_phrases = ["don't know", "dont know", "not sure", "no idea", "unfamiliar", "not certain"]
        is_dont_know = any(p in text for p in dont_know_phrases)

        if is_dont_know:
            overall = 3.0
            accuracy = 3.0
            relevance = 4.0
            clarity = 7.0
            depth = 2.0
            strengths = ["Honest acknowledgment of knowledge boundary."]
            missing = [f"Core technical principles of {topic}."]
            feedback = f"Candidate honestly acknowledged limited familiarity with {topic}."
            action = "decrease_difficulty"
        elif word_count < 10:
            overall = 4.5
            accuracy = 5.0
            relevance = 5.0
            clarity = 5.0
            depth = 3.0
            strengths = ["Brief response provided."]
            missing = [f"Deeper explanation and practical trade-offs of {topic}."]
            feedback = f"Short response provided for {topic}; needs deeper technical context."
            action = "follow_up"
        elif word_count >= 35:
            overall = 8.5
            accuracy = 8.5
            relevance = 8.5
            clarity = 8.5
            depth = 8.0
            strengths = [f"Detailed explanation of {topic} with practical context."]
            missing = ["Minor edge-case production details."]
            feedback = f"Strong and detailed technical response covering {topic}."
            action = "increase_difficulty"
        else:
            overall = 7.0
            accuracy = 7.0
            relevance = 7.0
            clarity = 7.0
            depth = 6.5
            strengths = [f"Clear explanation of {topic}."]
            missing = [f"Production edge-cases and performance trade-offs for {topic}."]
            feedback = f"Satisfactory answer covering basic principles of {topic}."
            action = "next_topic"

        return AnswerEvaluation(
            question_id=question_id,
            technical_accuracy=accuracy,
            relevance=relevance,
            clarity=clarity,
            depth=depth,
            overall=overall,
            strengths=strengths,
            missing_points=missing,
            missing_concepts=missing,
            follow_up_needed=(action == "follow_up"),
            recommended_next_action=action,
            feedback_summary=feedback,
            constructive_feedback=feedback,
            score_rationale=f"Assigned {overall}/10 based on candidate explanation depth ({word_count} words) and technical relevance.",
            expected_vs_actual=f"Expected clear technical explanation of {topic}. Received: '{candidate_answer[:60]}...'",
        )

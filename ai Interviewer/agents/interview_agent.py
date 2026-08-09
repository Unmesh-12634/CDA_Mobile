from typing import Dict, Any, Optional
from memory.interview_memory import InterviewMemory
from models.question import DifficultyLevel, Question, QuestionType
from prompts.interviewer_prompt import (
    GREETING_SYSTEM_PROMPT,
    GREETING_USER_PROMPT,
    CLOSING_SYSTEM_PROMPT,
    CLOSING_USER_PROMPT,
    INTERVIEWER_SYSTEM_PROMPT,
    INTERVIEWER_USER_PROMPT,
)
from services.groq_service import GroqService
from utils.logger import get_logger

logger = get_logger("interview_agent")


class InterviewerAgent:
    """Agent responsible for conducting the interview, generating dynamic questions, greetings, and human reactions."""

    def __init__(self, groq_service: GroqService):
        self.groq_service = groq_service

    def generate_initial_greeting(self, memory: InterviewMemory) -> str:
        """Generates a warm, professional human interviewer welcome greeting instantly (0ms)."""
        name = memory.config.candidate_name or "Candidate"
        role = memory.config.job_role
        level = memory.profile.experience_level or "Entry-Level"
        return f"Good morning, {name}! I'm delighted to welcome you to our interview for the {level} {role} position. I'm looking forward to learning more about your skills and experience, and I wish you all the best for today's session."

    def generate_closing_statement(self, memory: InterviewMemory) -> str:
        """Generates a warm, realistic human closing statement."""
        prompt = CLOSING_USER_PROMPT.format(
            candidate_name=memory.config.candidate_name,
            job_role=memory.config.job_role,
            total_questions=memory.current_turn,
        )

        closing = self.groq_service.generate(
            prompt=prompt,
            system_prompt=CLOSING_SYSTEM_PROMPT,
            temperature=0.7,
        )

        if not closing:
            return f"Thank you for your time today, {memory.config.candidate_name}! That concludes our technical interview session. I'll finalize your feedback report now. Have a wonderful day!"
        return closing.strip()

    def generate_next_question(self, memory: InterviewMemory) -> tuple[Question, str]:
        """Generates next question, interviewer reaction, and transition phrase based on candidate's last answer."""
        next_turn_number = memory.current_turn + 1
        last_turn = memory.get_last_turn()

        next_action = "next_topic"
        last_answer_satisfying = "N/A (First Question)"
        missing_concepts_str = "None"

        if last_turn:
            eval_data = last_turn.evaluation
            next_action = eval_data.recommended_next_action
            is_sat = getattr(eval_data, "is_satisfying", eval_data.overall >= 7.0)
            last_answer_satisfying = "YES (Satisfying & Complete)" if is_sat else "NO (Unsatisfying, Vague, or Missing Key Concepts)"

            combined_missing = eval_data.missing_points + getattr(eval_data, "incorrect_or_missing_concepts", [])
            if combined_missing:
                missing_concepts_str = ", ".join(list(set(combined_missing)))

        # Determine target topic
        target_topic = "Core Fundamentals"
        if memory.topics_remaining:
            target_topic = memory.topics_remaining[0]
        elif memory.plan and memory.plan.topic_allocations:
            target_topic = memory.plan.topic_allocations[next_turn_number % len(memory.plan.topic_allocations)].topic_name

        if next_action == "follow_up" and last_turn:
            target_topic = f"Follow-up on {last_turn.question.topic}"

        asked_list_str = "\n".join([f"- {q}" for q in memory.asked_question_texts]) if memory.asked_question_texts else "None"

        prompt = INTERVIEWER_USER_PROMPT.format(
            next_turn_number=next_turn_number,
            total_target_questions=memory.config.target_question_count,
            context_summary=memory.get_context_summary_for_llm(),
            asked_questions_list=asked_list_str,
            last_answer_satisfying=last_answer_satisfying,
            missing_concepts=missing_concepts_str,
            next_action=next_action,
            target_topic=target_topic,
            target_difficulty=memory.current_difficulty.value,
        )

        response_dict = self.groq_service.generate_json(
            prompt=prompt,
            system_prompt=INTERVIEWER_SYSTEM_PROMPT,
            temperature=0.6,
        )

        if not response_dict or "question_text" not in response_dict:
            logger.warning("LLM question generation produced invalid format. Using fallback question generator.")
            return self._fallback_question(memory, next_turn_number, target_topic)

        question_text = response_dict.get("question_text", "").strip()
        interviewer_reaction = response_dict.get("interviewer_reaction", "").strip()
        transition_phrase = response_dict.get("transition_phrase", "").strip()

        combined_transition = ""
        if interviewer_reaction:
            combined_transition += f"{interviewer_reaction} "
        if transition_phrase:
            combined_transition += transition_phrase

        if not combined_transition.strip():
            combined_transition = "Let me ask you the next question."

        topic = response_dict.get("topic", target_topic)
        q_type_str = response_dict.get("question_type", "Technical")
        diff_str = response_dict.get("difficulty", memory.current_difficulty.value)

        # Check for duplication
        if memory.is_question_duplicate(question_text):
            logger.warning(f"Duplicate question detected: '{question_text}'. Modifying prompt retry...")
            question_text += f" specifically regarding practical implementation in {memory.config.job_role} projects?"

        # Parse question type
        question_type = QuestionType.TECHNICAL
        for qt in QuestionType:
            if qt.value.lower() in q_type_str.lower():
                question_type = qt
                break

        # Parse difficulty level
        difficulty = memory.current_difficulty
        for dl in DifficultyLevel:
            if dl.value.lower() in diff_str.lower():
                difficulty = dl
                break

        question = Question(
            id=next_turn_number,
            text=question_text,
            topic=topic,
            question_type=question_type,
            difficulty=difficulty,
            rationale=response_dict.get("rationale"),
        )

        return question, combined_transition.strip()

    def _fallback_question(self, memory: InterviewMemory, turn_num: int, topic: str) -> tuple[Question, str]:
        """Provides a safe fallback question if the LLM output fails."""
        role = memory.config.job_role
        text = f"Could you explain your approach to architecture and performance optimization in {role} applications?"
        transition = "Alright, let's pivot slightly to system architecture."
        question = Question(
            id=turn_num,
            text=text,
            topic=topic,
            question_type=QuestionType.TECHNICAL,
            difficulty=memory.current_difficulty,
            rationale="Fallback technical question.",
        )
        return question, transition

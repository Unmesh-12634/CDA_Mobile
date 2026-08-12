import uuid
from typing import Dict, List, Optional, Set
from models.candidate import CandidateProfile
from models.evaluation import AnswerEvaluation
from models.interview import InterviewConfig, InterviewPlan, TurnRecord
from models.question import DifficultyLevel, Question, QuestionType
from utils.logger import get_logger

logger = get_logger("interview_memory")


class InterviewMemory:
    """Maintains state, session history, evaluations, and dynamic memory for an interview."""

    def __init__(self, config: InterviewConfig, profile: CandidateProfile, plan: Optional[InterviewPlan] = None):
        self.session_id: str = str(uuid.uuid4())
        self.config: InterviewConfig = config
        self.profile: CandidateProfile = profile
        self.plan: Optional[InterviewPlan] = plan

        self.history: List[TurnRecord] = []
        self.current_difficulty: DifficultyLevel = config.difficulty
        self.current_turn: int = 0

        self.topics_covered: Set[str] = set()
        self.topics_remaining: List[str] = []
        if plan:
            self.topics_remaining = [alloc.topic_name for alloc in plan.topic_allocations]

        self.strong_topics: Set[str] = set()
        self.weak_topics: Set[str] = set()
        self.asked_question_texts: List[str] = []
        self.consecutive_good_answers: int = 0
        self.consecutive_poor_answers: int = 0

        # Evolving Candidate Beliefs & Uncertainty Matrix
        self.candidate_beliefs: Dict[str, str] = {
            "AI & ML Stack": "Unverified / High Uncertainty",
            "Core Technical Fundamentals": "Unverified / High Uncertainty",
            "System Architecture & Scaling": "Unverified / High Uncertainty",
            "Database & Storage": "Unverified / High Uncertainty",
            "DevOps & Deployment": "Unverified / High Uncertainty",
            "Team Leadership & Ownership": "Unverified / High Uncertainty",
        }

    def add_turn(self, question: Question, candidate_answer: str, evaluation: AnswerEvaluation) -> TurnRecord:
        """Records a completed turn, updates topic tracking, evolving beliefs, and adaptive difficulty."""
        self.current_turn += 1
        turn = TurnRecord(
            turn_number=self.current_turn,
            question=question,
            candidate_answer=candidate_answer,
            evaluation=evaluation,
        )
        self.history.append(turn)
        self.asked_question_texts.append(question.text.lower())

        # Update topics
        if question.topic:
            self.topics_covered.add(question.topic)
            if question.topic in self.topics_remaining:
                self.topics_remaining.remove(question.topic)

        # Update Evolving Beliefs Matrix based on turn performance & topic
        topic_domain = question.topic or "Technical Fundamentals"
        if evaluation.overall >= 7.5:
            self.strong_topics.add(topic_domain)
            self.candidate_beliefs[topic_domain] = f"Validated Strong (Score {evaluation.overall:.1f}/10)"
            self.consecutive_good_answers += 1
            self.consecutive_poor_answers = 0
        elif evaluation.overall <= 5.0:
            self.weak_topics.add(topic_domain)
            self.candidate_beliefs[topic_domain] = f"Validated Gap (Score {evaluation.overall:.1f}/10)"
            self.consecutive_poor_answers += 1
            self.consecutive_good_answers = 0
        else:
            self.candidate_beliefs[topic_domain] = f"Partially Validated (Score {evaluation.overall:.1f}/10)"
            self.consecutive_good_answers = 0
            self.consecutive_poor_answers = 0

        # Adapt difficulty dynamically
        self._adapt_difficulty(evaluation)
        logger.info(f"Recorded Turn #{self.current_turn}: Score={evaluation.overall}, NextAction={evaluation.recommended_next_action}, Difficulty={self.current_difficulty.value}")
        return turn

    def _adapt_difficulty(self, evaluation: AnswerEvaluation) -> None:
        """Dynamically adjusts difficulty level based on candidate performance."""
        if evaluation.recommended_next_action == "increase_difficulty" or self.consecutive_good_answers >= 2:
            if self.current_difficulty == DifficultyLevel.BEGINNER:
                self.current_difficulty = DifficultyLevel.INTERMEDIATE
            elif self.current_difficulty == DifficultyLevel.INTERMEDIATE:
                self.current_difficulty = DifficultyLevel.ADVANCED
        elif evaluation.recommended_next_action == "decrease_difficulty" or self.consecutive_poor_answers >= 2:
            if self.current_difficulty == DifficultyLevel.ADVANCED:
                self.current_difficulty = DifficultyLevel.INTERMEDIATE
            elif self.current_difficulty == DifficultyLevel.INTERMEDIATE:
                self.current_difficulty = DifficultyLevel.BEGINNER

    def is_question_duplicate(self, question_text: str) -> bool:
        """Checks if a similar question has already been asked."""
        q_clean = question_text.strip().lower()
        for asked in self.asked_question_texts:
            if q_clean in asked or asked in q_clean:
                return True
        return False

    def get_last_turn(self) -> Optional[TurnRecord]:
        """Returns the most recent Q&A turn record if any."""
        return self.history[-1] if self.history else None

    def get_context_summary_for_llm(self) -> str:
        """Builds a comprehensive memory summary for LLM question generation."""
        summary_lines = [
            f"Job Role: {self.config.job_role}",
            f"Interview Type: {self.config.interview_type.value}",
            f"Current Difficulty Level: {self.current_difficulty.value}",
            f"Turns Completed: {self.current_turn} / {self.config.target_question_count}",
            f"\n--- CANDIDATE DETAILS & RESUME PROFILE ---",
            self.profile.to_detailed_prompt_context(),
            f"\n--- INTERVIEWER EVOLVING BELIEF & UNCERTAINTY MATRIX ---",
        ]
        for domain, status in self.candidate_beliefs.items():
            summary_lines.append(f"  • {domain}: {status}")

        if self.topics_covered:
            summary_lines.append(f"\nTopics & Domains Evaluated: {', '.join(list(self.topics_covered))}")
        if self.strong_topics:
            summary_lines.append(f"Candidate Strong Areas: {', '.join(list(self.strong_topics))}")
        if self.weak_topics:
            summary_lines.append(f"Candidate Weak Areas: {', '.join(list(self.weak_topics))}")

        if self.history:
            last = self.history[-1]
            summary_lines.append(f"\n--- LAST TURN REVIEW ---")
            summary_lines.append(f"Last Question Asked: \"{last.question.text}\" (Topic: {last.question.topic})")
            summary_lines.append(f"Candidate Answer: \"{last.candidate_answer}\"")
            summary_lines.append(f"Evaluation Score: {last.evaluation.overall}/10 (Accuracy: {last.evaluation.technical_accuracy}, Depth: {last.evaluation.depth})")
            summary_lines.append(f"Strengths Noted: {', '.join(last.evaluation.strengths[:3]) if last.evaluation.strengths else 'Demonstrated foundational knowledge'}")
            summary_lines.append(f"Missing Points: {', '.join(last.evaluation.missing_points[:3]) if last.evaluation.missing_points else 'Detailed production metrics'}")
            summary_lines.append(f"Recommended Action: {last.evaluation.recommended_next_action}")

        return "\n".join(summary_lines)

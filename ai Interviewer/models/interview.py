from enum import Enum
from typing import Dict, List, Optional
from pydantic import BaseModel, Field

from models.candidate import CandidateProfile
from models.evaluation import AnswerEvaluation
from models.question import DifficultyLevel, Question


class InterviewType(str, Enum):
    TECHNICAL = "Technical"
    HR = "HR"
    BEHAVIORAL = "Behavioral"
    RESUME_BASED = "Resume Based"
    MIXED = "Mixed"


class InterviewLength(str, Enum):
    SHORT = "Short"  # ~5 questions
    STANDARD = "Standard"  # ~8 questions
    DETAILED = "Detailed"  # ~12 questions


class InterviewConfig(BaseModel):
    """Initial user configuration for the interview session."""

    candidate_name: str = "Candidate"
    job_role: str = "Software Engineer"
    experience_level: str = "Mid-Level"  # Entry-Level, Mid-Level, Senior, Lead/Architect
    target_career_goal: Optional[str] = None
    interview_type: InterviewType = InterviewType.MIXED
    difficulty: DifficultyLevel = DifficultyLevel.INTERMEDIATE
    length: InterviewLength = InterviewLength.STANDARD
    target_question_count: int = 8
    resume_path: Optional[str] = None


class TopicAllocation(BaseModel):
    """Topic weight allocation in interview plan."""
    topic_name: str
    weight_percentage: float
    target_questions: int


class InterviewPlan(BaseModel):
    """Strategic plan generated prior to asking questions."""

    job_role: str
    focus_summary: str
    topic_allocations: List[TopicAllocation] = Field(default_factory=list)
    key_objectives: List[str] = Field(default_factory=list)


class TurnRecord(BaseModel):
    """Record of a single interview Q&A turn."""

    turn_number: int
    question: Question
    candidate_answer: str
    evaluation: AnswerEvaluation


class QuestionReview(BaseModel):
    """Detailed post-interview question review item."""

    question_id: int
    question: str
    candidate_answer: str
    score: float
    what_was_good: List[str] = Field(default_factory=list)
    what_was_missing: List[str] = Field(default_factory=list)
    how_to_improve: str = ""
    example_better_answer: str = ""


class InterviewReport(BaseModel):
    """Final comprehensive report generated at the end of the interview."""

    candidate_name: str
    job_role: str
    interview_type: str
    difficulty: str
    overall_score: float = Field(ge=0.0, le=100.0)

    # Category Scores (out of 100)
    technical_score: float = Field(ge=0.0, le=100.0)
    communication_score: float = Field(ge=0.0, le=100.0)
    problem_solving_score: float = Field(ge=0.0, le=100.0)
    resume_knowledge_score: float = Field(ge=0.0, le=100.0)
    clarity_score: float = Field(ge=0.0, le=100.0)
    role_readiness_score: float = Field(ge=0.0, le=100.0)

    hiring_readiness: str  # "Needs Significant Preparation", "Developing", "Interview Ready", "Strong Candidate"
    summary: str
    strong_areas: List[str] = Field(default_factory=list)
    areas_for_improvement: List[str] = Field(default_factory=list)
    recommended_topics_to_study: List[str] = Field(default_factory=list)
    question_reviews: List[QuestionReview] = Field(default_factory=list)


class InterviewResponse(BaseModel):
    """Decoupled response object returned by InterviewService to client interfaces."""

    session_id: str
    is_completed: bool = False
    initial_greeting: Optional[str] = None
    closing_statement: Optional[str] = None
    current_question: Optional[Question] = None
    turn_number: int = 0
    total_target_questions: int = 8
    transition_phrase: str = ""
    report: Optional[InterviewReport] = None
    report_json_path: Optional[str] = None
    report_txt_path: Optional[str] = None

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


class HireRecommendation(str, Enum):
    STRONG_HIRE = "Strong Hire"
    HIRE = "Hire"
    LEAN_HIRE = "Lean Hire"
    BORDERLINE = "Borderline"
    LEAN_NO_HIRE = "Lean No Hire"
    NO_HIRE = "No Hire"


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
    voice_persona: str = "guy"


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
    interviewer_expectation: str = ""
    concepts_covered: List[str] = Field(default_factory=list)
    concepts_partially_covered: List[str] = Field(default_factory=list)
    missing_concepts: List[str] = Field(default_factory=list)
    practical_vs_theory: str = "Balanced"
    tradeoffs_discussed: bool = False
    architecture_thinking_shown: bool = False
    communication_structure: str = "Structured & Clear"
    confidence_trend: str = "Confident"
    what_was_good: List[str] = Field(default_factory=list)
    what_was_missing: List[str] = Field(default_factory=list)
    how_to_improve: str = ""
    example_better_answer: str = ""
    senior_coaching_diff: str = ""


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
    engineering_judgement_score: float = Field(default=75.0, ge=0.0, le=100.0)
    production_readiness_score: float = Field(default=75.0, ge=0.0, le=100.0)

    hire_recommendation: HireRecommendation = HireRecommendation.HIRE
    hiring_readiness: str  # "Needs Preparation", "Developing", "Interview Ready", "Strong Candidate"
    hiring_panel_rationale: str = ""
    hiring_risks: List[str] = Field(default_factory=list)
    recommendation_confidence: str = "High Confidence"
    suggested_salary_level: str = "INR 12 - 18 LPA"

    summary: str
    recruiter_notes: List[str] = Field(default_factory=list)
    trajectory_analysis: str = ""
    evidence_backed_conclusions: List[str] = Field(default_factory=list)

    # 14-Dimension Narrative Evaluations
    technical_maturity_eval: str = ""
    communication_style_eval: str = ""
    problem_solving_eval: str = ""
    engineering_judgement_eval: str = ""
    ownership_eval: str = ""
    production_readiness_eval: str = ""
    resume_authenticity_eval: str = ""
    learning_potential_eval: str = ""

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

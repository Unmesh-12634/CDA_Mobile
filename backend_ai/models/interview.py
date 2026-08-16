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
    job_description: Optional[str] = None
    experience_level: str = "Mid-Level"  # Entry-Level, Mid-Level, Senior, Lead/Architect
    target_career_goal: Optional[str] = None
    interview_type: InterviewType = InterviewType.MIXED
    difficulty: DifficultyLevel = DifficultyLevel.INTERMEDIATE
    length: InterviewLength = InterviewLength.STANDARD
    target_question_count: int = 8
    resume_path: Optional[str] = None
    voice_persona: str = "guy"
    enrolled_courses: List[str] = Field(default_factory=list)
    skills: List[str] = Field(default_factory=list)


class TopicAllocation(BaseModel):
    """Topic weight allocation in interview plan."""
    topic_name: str
    weight_percentage: float
    target_questions: int


class InterviewPlan(BaseModel):
    """Strategic plan generated prior to asking questions based on 360 resume & JD analysis."""

    job_role: str
    focus_summary: str
    resume_vs_jd_matches: List[str] = Field(default_factory=list)
    resume_vs_jd_gaps: List[str] = Field(default_factory=list)
    projects_to_explore: List[str] = Field(default_factory=list)
    skills_to_verify: List[str] = Field(default_factory=list)
    topic_allocations: List[TopicAllocation] = Field(default_factory=list)
    key_objectives: List[str] = Field(default_factory=list)


class TurnRecord(BaseModel):
    """Record of a single interview Q&A turn."""

    turn_number: int
    question: Question
    candidate_answer: str
    evaluation: AnswerEvaluation


class QuestionReview(BaseModel):
    """Detailed post-interview question review item with complete evidence breakdown."""

    question_id: int
    question_type: str = Field(default="Technical")
    competency_tested: str = Field(default="Core Fundamentals")
    why_this_question_was_asked: str = Field(default="")
    question: str
    candidate_answer: str
    score: float
    score_rationale: str = Field(default="")
    interviewer_expectation: str = Field(default="")
    concepts_covered: List[str] = Field(default_factory=list)
    concepts_partially_covered: List[str] = Field(default_factory=list)
    incorrect_points: List[str] = Field(default_factory=list)
    missing_concepts: List[str] = Field(default_factory=list)
    actual_experience_evidence: str = Field(default="")
    hypothetical_reasoning: str = Field(default="")
    practical_vs_theory: str = Field(default="Balanced")
    tradeoffs_discussed: bool = False
    architecture_thinking_shown: bool = False
    communication_structure: str = Field(default="Structured & Clear")
    confidence_trend: str = Field(default="Confident")
    what_was_good: List[str] = Field(default_factory=list)
    what_was_missing: List[str] = Field(default_factory=list)
    how_answer_affected_interview: str = Field(default="")
    why_next_question_was_chosen: str = Field(default="")
    how_to_improve: str = Field(default="")
    example_better_answer: str = Field(default="")
    senior_coaching_diff: str = Field(default="")


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

    # Evidence Coverage Matrix (Validated vs Partially Validated vs Unverified vs Not Sampled)
    resume_coverage_percentage: float = Field(default=85.0, ge=0.0, le=100.0)
    validated_skills: List[str] = Field(default_factory=list)
    partially_validated_skills: List[str] = Field(default_factory=list)
    unverified_skills: List[str] = Field(default_factory=list)
    not_sampled_skills: List[str] = Field(default_factory=list)
    
    projects_evaluated: List[str] = Field(default_factory=list)
    partially_validated_projects: List[str] = Field(default_factory=list)
    not_sampled_projects: List[str] = Field(default_factory=list)
    
    certifications_status: List[str] = Field(default_factory=list)
    hackathons_status: List[str] = Field(default_factory=list)
    leadership_status: List[str] = Field(default_factory=list)
    hackathons_and_certs_evaluated: List[str] = Field(default_factory=list)

    hire_recommendation: HireRecommendation = HireRecommendation.HIRE
    hiring_readiness: str  # "Needs Preparation", "Developing", "Interview Ready", "Strong Candidate"
    hiring_panel_rationale: str = ""
    hiring_risks: List[str] = Field(default_factory=list)
    recommendation_confidence: str = "Medium Confidence (Limited Scope)"
    suggested_salary_level: str = "INR 12 - 18 LPA"
    salary_estimate_note: str = Field(default="Estimated baseline market salary range based on candidate experience; not tied to technical score.")
    scope_limit_notice: str = Field(default="Interview scope was limited to configured question count. Un-sampled skills are marked as Not Sampled rather than weak.")

    summary: str
    recruiter_notes: List[str] = Field(default_factory=list)
    interviewer_notes: List[str] = Field(default_factory=list, description="Genuine Engineering Manager observations")
    trajectory_analysis: str = ""
    evidence_backed_conclusions: List[str] = Field(default_factory=list)

    # Narrative Dimension Evaluations
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

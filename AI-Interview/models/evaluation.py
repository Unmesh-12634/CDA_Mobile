from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class EvidenceType(str, Enum):
    DEMONSTRATED_PRACTICAL = "Demonstrated Practical Experience"
    HYPOTHETICAL_SOLUTION = "Hypothetical Solution / Reasoning"
    MEMORIZED_DEFINITION = "Memorized Theoretical Definition"
    UNVERIFIED_CLAIM = "Unverified Claim"


class AnswerEvaluation(BaseModel):
    """Structured evidence-based evaluation of a candidate's answer to a single question."""

    question_id: int
    question_intent: str = Field(default="", description="The specific intent and competency tested by this question")
    expected_signals: List[str] = Field(default_factory=list, description="Key technical signals a strong answer to THIS question should contain")
    stt_normalized_answer: str = Field(default="", description="Candidate's actual technical meaning after STT speech normalization")
    
    technical_accuracy: float = Field(ge=0.0, le=10.0, default=7.0)
    relevance: float = Field(ge=0.0, le=10.0, default=7.0)
    clarity: float = Field(ge=0.0, le=10.0, default=7.0)
    depth: float = Field(ge=0.0, le=10.0, default=7.0)
    overall: float = Field(ge=0.0, le=10.0, default=7.0)
    engineering_judgement_score: float = Field(ge=0.0, le=10.0, default=7.0)
    tradeoff_analysis_score: float = Field(ge=0.0, le=10.0, default=7.0)
    confidence_score: float = Field(ge=0.0, le=10.0, default=7.0)
    
    intent_understanding: str = Field(default="", description="Real technical intent understood despite STT noise")
    evidence_type: EvidenceType = Field(default=EvidenceType.DEMONSTRATED_PRACTICAL)
    practical_vs_theory_signal: str = Field(default="Balanced", description="Signal: Strong Practical Experience, Memorized Theory, or Balanced")
    
    correct_points: List[str] = Field(default_factory=list, description="Technically accurate points stated by candidate")
    partially_correct_points: List[str] = Field(default_factory=list, description="Partially accurate or ambiguous points")
    incorrect_points: List[str] = Field(default_factory=list, description="Explicitly incorrect statements")
    missing_concepts: List[str] = Field(default_factory=list, description="Materially important concepts omitted for THIS question")
    
    is_satisfying: bool = Field(default=True, description="True if answer is accurate and satisfying for the question intent")
    strengths: List[str] = Field(default_factory=list)
    missing_points: List[str] = Field(default_factory=list)
    
    score_rationale: str = Field(default="", description="Evidence-backed explanation for assigned score")
    expected_vs_actual: str = Field(default="", description="Expectations for THIS question vs actual candidate response")
    senior_coaching_notes: str = Field(default="", description="Senior Staff Engineer coaching differential")
    question_specific_improvement: str = Field(default="", description="Question-specific advice connecting what was missing to why it matters")
    
    follow_up_needed: bool = Field(default=False)
    recommended_next_action: str = Field(
        default="next_topic",
        description="Options: follow_up, increase_difficulty, decrease_difficulty, next_topic, challenge_tradeoff",
    )
    feedback_summary: Optional[str] = None
    constructive_feedback: Optional[str] = None

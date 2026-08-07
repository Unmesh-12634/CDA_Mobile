from typing import List, Optional
from pydantic import BaseModel, Field


class AnswerEvaluation(BaseModel):
    """Structured evaluation of a candidate's answer to a single question."""

    question_id: int
    technical_accuracy: float = Field(ge=1.0, le=10.0, default=7.0)
    relevance: float = Field(ge=1.0, le=10.0, default=7.0)
    clarity: float = Field(ge=1.0, le=10.0, default=7.0)
    depth: float = Field(ge=1.0, le=10.0, default=7.0)
    overall: float = Field(ge=1.0, le=10.0, default=7.0)
    engineering_judgement_score: float = Field(ge=1.0, le=10.0, default=7.0)
    tradeoff_analysis_score: float = Field(ge=1.0, le=10.0, default=7.0)
    confidence_score: float = Field(ge=1.0, le=10.0, default=7.0)
    
    intent_understanding: str = Field(default="N/A", description="Real technical intent understood despite STT noise")
    practical_vs_theory_signal: str = Field(default="Balanced", description="Signal: Strong Practical Experience, Memorized Theory, or Balanced")
    
    concepts_covered: List[str] = Field(default_factory=list)
    concepts_partially_covered: List[str] = Field(default_factory=list)
    incorrect_or_missing_concepts: List[str] = Field(default_factory=list)
    
    is_satisfying: bool = Field(default=True, description="True if answer is accurate and satisfying")
    strengths: List[str] = Field(default_factory=list)
    missing_points: List[str] = Field(default_factory=list)
    
    expected_vs_actual: str = Field(default="N/A", description="Expectations vs actual candidate response")
    senior_coaching_notes: str = Field(default="N/A", description="Senior Staff Engineer coaching differential")
    
    follow_up_needed: bool = Field(default=False)
    recommended_next_action: str = Field(
        default="next_topic",
        description="Options: follow_up, increase_difficulty, decrease_difficulty, next_topic, challenge_tradeoff",
    )
    feedback_summary: Optional[str] = None
    constructive_feedback: Optional[str] = None

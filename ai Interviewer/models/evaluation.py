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
    is_satisfying: bool = Field(default=True, description="True if answer is accurate and satisfying, False if incorrect/vague/missing key concepts")
    strengths: List[str] = Field(default_factory=list)
    missing_points: List[str] = Field(default_factory=list)
    incorrect_or_missing_concepts: List[str] = Field(default_factory=list)
    follow_up_needed: bool = Field(default=False)
    recommended_next_action: str = Field(
        default="next_topic",
        description="Options: follow_up, increase_difficulty, decrease_difficulty, next_topic",
    )
    feedback_summary: Optional[str] = None

from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class QuestionType(str, Enum):
    RESUME = "Resume Based"
    TECHNICAL = "Technical"
    CONCEPTUAL = "Conceptual"
    SCENARIO = "Scenario Based"
    PROBLEM_SOLVING = "Problem Solving"
    PROJECT_DEEP_DIVE = "Project Deep Dive"
    ARCHITECTURE = "System Architecture"
    BEHAVIORAL = "Behavioral"
    HR = "HR"
    FOLLOW_UP = "Follow-up"


class DifficultyLevel(str, Enum):
    BEGINNER = "Beginner"
    INTERMEDIATE = "Intermediate"
    ADVANCED = "Advanced"


class Question(BaseModel):
    """Represents a single interview question."""

    id: int
    text: str
    topic: str
    question_type: QuestionType = QuestionType.TECHNICAL
    difficulty: DifficultyLevel = DifficultyLevel.INTERMEDIATE
    rationale: Optional[str] = None
    expected_key_points: list[str] = Field(default_factory=list)

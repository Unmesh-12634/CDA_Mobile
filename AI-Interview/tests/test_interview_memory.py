from memory.interview_memory import InterviewMemory
from models.candidate import CandidateProfile
from models.evaluation import AnswerEvaluation
from models.interview import InterviewConfig, DifficultyLevel
from models.question import Question, QuestionType


def test_interview_memory_turn_tracking():
    config = InterviewConfig(candidate_name="Unmesh", target_question_count=5, difficulty=DifficultyLevel.BEGINNER)
    profile = CandidateProfile(name="Unmesh")
    memory = InterviewMemory(config=config, profile=profile)

    q = Question(id=1, text="Explain OOP principles.", topic="Java", question_type=QuestionType.TECHNICAL)
    eval_result = AnswerEvaluation(
        question_id=1,
        overall=9.0,
        technical_accuracy=9.0,
        strengths=["Clear OOP explanation"],
        recommended_next_action="increase_difficulty",
    )

    memory.add_turn(q, "OOP stands for Object Oriented Programming...", eval_result)

    assert memory.current_turn == 1
    assert "Java" in memory.topics_covered
    assert "Java" in memory.strong_topics
    assert memory.history[0].candidate_answer.startswith("OOP stands")
    assert memory.current_difficulty == DifficultyLevel.INTERMEDIATE

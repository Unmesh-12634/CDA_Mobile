from memory.interview_memory import InterviewMemory
from models.candidate import CandidateProfile
from models.evaluation import AnswerEvaluation
from models.interview import InterviewConfig
from models.question import Question, QuestionType


def test_question_duplication_prevention():
    config = InterviewConfig(candidate_name="Tester")
    profile = CandidateProfile(name="Tester")
    memory = InterviewMemory(config=config, profile=profile)

    q1 = Question(id=1, text="What is Dependency Injection in Spring?", topic="Spring", question_type=QuestionType.TECHNICAL)
    eval1 = AnswerEvaluation(question_id=1, overall=7.0)
    memory.add_turn(q1, "DI is inversion of control...", eval1)

    assert memory.is_question_duplicate("What is Dependency Injection in Spring?") is True
    assert memory.is_question_duplicate("Explain how React hooks work?") is False

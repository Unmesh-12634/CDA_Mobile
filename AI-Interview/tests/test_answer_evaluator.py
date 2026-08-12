from unittest.mock import MagicMock
from agents.answer_evaluator import AnswerEvaluatorAgent
from models.evaluation import AnswerEvaluation
from models.question import Question, QuestionType


def test_answer_evaluator_empty_answer():
    mock_groq = MagicMock()
    agent = AnswerEvaluatorAgent(mock_groq)

    q = Question(id=1, text="Explain Spring Boot auto configuration.", topic="Spring", question_type=QuestionType.TECHNICAL)
    result = agent.evaluate_answer(q, "", "Java Developer")

    assert result.overall == 2.0
    assert result.recommended_next_action == "decrease_difficulty"
    # Should not call Groq for empty answers
    mock_groq.generate_structured.assert_not_called()


def test_answer_evaluator_mock_groq():
    mock_groq = MagicMock()
    expected_eval = AnswerEvaluation(
        question_id=1,
        technical_accuracy=9.0,
        relevance=9.0,
        clarity=8.5,
        depth=8.0,
        overall=8.6,
        strengths=["Great explanation of @EnableAutoConfiguration"],
        recommended_next_action="increase_difficulty",
    )
    mock_groq.generate_structured.return_value = expected_eval

    agent = AnswerEvaluatorAgent(mock_groq)
    q = Question(id=1, text="Explain Spring Boot auto configuration.", topic="Spring", question_type=QuestionType.TECHNICAL)
    result = agent.evaluate_answer(q, "Auto-configuration attempts to automatically configure Spring app...", "Java Developer")

    assert result.overall == 8.6
    assert result.recommended_next_action == "increase_difficulty"

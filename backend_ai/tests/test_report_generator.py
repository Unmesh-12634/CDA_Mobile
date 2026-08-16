from unittest.mock import MagicMock
from agents.report_agent import ReportGeneratorAgent
from memory.interview_memory import InterviewMemory
from models.candidate import CandidateProfile
from models.evaluation import AnswerEvaluation
from models.interview import InterviewConfig, InterviewReport
from models.question import Question, QuestionType


def test_report_fallback():
    mock_groq = MagicMock()
    mock_groq.generate_structured.return_value = None  # Force fallback trigger

    agent = ReportGeneratorAgent(mock_groq)

    config = InterviewConfig(candidate_name="Candidate A", job_role="Python Developer")
    profile = CandidateProfile(name="Candidate A")
    memory = InterviewMemory(config=config, profile=profile)

    q1 = Question(id=1, text="Explain Python GIL.", topic="Python", question_type=QuestionType.TECHNICAL)
    eval1 = AnswerEvaluation(question_id=1, overall=8.0)
    memory.add_turn(q1, "GIL locks the interpreter...", eval1)

    report = agent.generate_report(memory)

    assert report.candidate_name == "Candidate A"
    assert report.job_role == "Python Developer"
    assert report.overall_score == 80.0
    assert report.hiring_readiness in ["Interview Ready", "Developing", "Strong Candidate"]

    formatted_text = agent.generate_formatted_text_report(report)
    assert "CDA AI MOCK INTERVIEW PERFORMANCE REPORT" in formatted_text
    assert "Candidate A" in formatted_text

import os
import sys
from pathlib import Path

# Force UTF-8 output encoding for Windows terminal
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

# Add parent directory to sys.path
sys.path.insert(0, str(Path(__file__).parent.parent))

from models.interview import InterviewConfig, InterviewType, DifficultyLevel, InterviewLength
from services.interview_service import InterviewService
from services.resume_service import ResumeService
from services.groq_service import GroqService
from utils.logger import get_logger

logger = get_logger("e2e_resume_test")


def test_full_interview_flow():
    resume_path = r"D:\Resume\aiml\Unmesh_Joshi_AI_ML.pdf"
    print(f"\n==================================================")
    print(f"  STARTING E2E AI INTERVIEW SYSTEM TEST WITH RESUME")
    print(f"==================================================")
    print(f"Resume Path: {resume_path}")

    groq_service = GroqService()
    resume_service = ResumeService(groq_service)

    # 1. Parse Resume
    profile = resume_service.process_resume(resume_path, candidate_name="Unmesh Joshi")
    print(f" Parsed Resume Successfully!")
    print(f"  Candidate Name: {profile.name}")
    print(f"  Level: {profile.experience_level}")
    print(f"  Top Skills: {', '.join(profile.skills[:10]) if profile.skills else 'N/A'}")
    print(f"  Projects Found: {len(profile.projects)}")
    for p in profile.projects:
        print(f"    - {p.title}: {p.technologies}")

    print(f"\nContext Summary for Agents:\n{profile.to_brief_summary()}\n")

    # 2. Initialize Service & Config
    service = InterviewService(groq_service)
    config = InterviewConfig(
        candidate_name=profile.name or "Unmesh",
        job_role="AI/ML Full Stack Engineer",
        experience_level="Mid-Senior",
        interview_type=InterviewType.MIXED,
        difficulty=DifficultyLevel.INTERMEDIATE,
        length=InterviewLength.SHORT,
        target_question_count=5,
        resume_path=resume_path,
    )

    # 3. Start Session
    response = service.start_session(config)
    session_id = response.session_id
    print(f" Session Started! ID: {session_id}")
    print(f" Greeting: {response.initial_greeting}\n")

    current_q = response.current_question
    turn = 1

    # Simulated Candidate Answers for AI/ML Engineer Role
    candidate_answers = [
        "In my Meducate project, I built a hybrid RAG architecture using LangChain, FastEmbed, and Qdrant vector database. To keep latency under 200ms, I implemented payload indexing and Redis caching for frequent user queries, while ensuring fallbacks for API rate limits.",
        "For multi-tenant isolation in RAG Creator Studio, I decoupled database schemas per organization using Row-Level Security (RLS) in PostgreSQL, and configured isolated Qdrant vector collection namespaces with strict JWT authentication.",
        "When handling concurrent LLM streaming requests, I used Python asyncio with FastAPI websockets. I implemented token streaming with backpressure control and backoff retries to prevent client-side UI freezing.",
        "To evaluate RAG retrieval quality, I used Ragas framework measuring Context Precision, Recall, and Faithfulness. When hallucinations occurred, I optimized chunking strategy with dynamic semantic splitting and added strict system prompt guardrails.",
        "To deploy this full-stack AI system at scale, I dockerized the FastAPI application and containerized worker processes using Cloud Run with autoscaling, setting up a CI/CD pipeline via GitHub Actions with pre-deployment unit and integration tests."
    ]

    while not response.is_completed and current_q:
        print(f"--------------------------------------------------")
        print(f"Turn #{turn} [{current_q.question_type.value} | {current_q.topic}]:")
        print(f"Q: {current_q.text}")
        
        answer = candidate_answers[(turn - 1) % len(candidate_answers)]
        print(f"A: \"{answer}\"")

        response = service.process_answer(session_id, answer)

        if response.current_question:
            current_q = response.current_question
        turn += 1

    print(f"\n==================================================")
    print(f"  INTERVIEW SESSION COMPLETED SUCCESSFULLY")
    print(f"==================================================")
    print(f"Closing Statement: {response.closing_statement}\n")

    report = response.report
    assert report is not None, "Report should not be None"
    print(f"Overall Score: {report.overall_score}/100")
    print(f"Hiring Readiness: {report.hiring_readiness}")
    print(f"Hire Recommendation: {report.hire_recommendation}")
    print(f"Question Reviews Generated: {len(report.question_reviews)}")

    formatted_txt = service.report_agent.generate_formatted_text_report(report)
    print(f"\n{formatted_txt}\n")

    print(f" Full Text Report File: {response.report_txt_path}")
    print(f" JSON Report File: {response.report_json_path}")
    print(f" ALL TEST CASES PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    test_full_interview_flow()

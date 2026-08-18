from typing import Dict, Optional
from agents.answer_evaluator import AnswerEvaluatorAgent
from agents.interview_agent import InterviewerAgent
from agents.interview_planner import InterviewPlannerAgent
from agents.report_agent import ReportGeneratorAgent
from config.settings import settings
from memory.interview_memory import InterviewMemory
from models.interview import InterviewConfig, InterviewResponse
from services.groq_service import GroqService
from services.resume_service import ResumeService
from services.supabase_service import SupabaseRepository
from utils.file_utils import save_report_files
from utils.logger import get_logger

logger = get_logger("interview_service")


class InterviewService:
    """Core domain facade encapsulating interview engine lifecycle and 100% DB-driven state transitions."""

    def __init__(self, groq_service: Optional[GroqService] = None, repository: Optional[SupabaseRepository] = None):
        self.groq_service = groq_service or GroqService()
        self.repo = repository or SupabaseRepository()
        self.resume_service = ResumeService(self.groq_service)
        self.planner_agent = InterviewPlannerAgent(self.groq_service)
        self.evaluator_agent = AnswerEvaluatorAgent(self.groq_service)
        self.interviewer_agent = InterviewerAgent(self.groq_service)
        self.report_agent = ReportGeneratorAgent(self.groq_service)

        # In-memory RAM cache backed 100% by Supabase DB
        self.sessions: Dict[str, InterviewMemory] = {}

    def start_session(self, config: InterviewConfig) -> InterviewResponse:
        """Initializes a new interview session, fetches DB rubric, persists session state to Supabase DB, and generates Q1."""
        logger.info(f"Starting new 100% DB-driven interview session for '{config.candidate_name}' ({config.job_role})")

        # 1. Fetch matching dynamic evaluation rubric from Supabase DB
        rubric_data = self.repo.get_rubric_for_role(config.job_role)
        rubric_id = rubric_data.get("id")

        # 2. Process candidate resume if provided
        profile = self.resume_service.process_resume(config.resume_path or "", config.candidate_name)
        if config.experience_level and config.experience_level != "Mid-Level":
            profile.experience_level = config.experience_level
        if config.target_career_goal:
            profile.target_career_goal = config.target_career_goal

        # 3. Generate strategic interview plan
        plan = self.planner_agent.create_plan(config, profile)

        # 4. Instantiate InterviewMemory & RAM Cache
        memory = InterviewMemory(config=config, profile=profile, plan=plan)
        self.sessions[memory.session_id] = memory

        # 5. Generate initial greeting and Question 1
        greeting = self.interviewer_agent.generate_initial_greeting(memory)
        q1, transition = self.interviewer_agent.generate_next_question(memory)
        memory.current_question = q1

        # 6. Persist initial session record directly into Supabase PostgreSQL DB
        try:
            db_session_payload = {
                "session_id": memory.session_id,
                "candidate_name": config.candidate_name,
                "job_role": config.job_role,
                "seniority_level": config.experience_level,
                "interview_type": config.interview_type.value,
                "difficulty": config.difficulty.value,
                "target_question_count": config.target_question_count,
                "current_turn": 1,
                "session_status": "IN_PROGRESS",
                "rubric_id": rubric_id,
                "config_data": config.model_dump(mode="json"),
                "turn_records": [],
            }
            self.repo.create_session(db_session_payload)
        except Exception as e:
            logger.warning(f"Non-fatal warning creating session in Supabase DB: {e}")

        return InterviewResponse(
            session_id=memory.session_id,
            is_completed=False,
            initial_greeting=greeting,
            current_question=q1,
            turn_number=1,
            total_target_questions=config.target_question_count,
            transition_phrase=transition,
        )

    def process_answer(self, session_id: str, candidate_answer: str) -> InterviewResponse:
        """Processes candidate answer for current turn, evaluates it against DB rubrics, updates Supabase DB, and returns next question."""
        memory = self.sessions.get(session_id)
        
        # If RAM cache misses (e.g. server restart), reconstruct from Supabase DB
        if not memory:
            logger.info(f"Session '{session_id}' RAM cache miss. Restoring state directly from Supabase DB...")
            db_session = self.repo.get_session(session_id)
            if db_session:
                cfg_data = db_session.get("config_data") or {}
                config = InterviewConfig(
                    candidate_name=db_session.get("candidate_name", "Candidate"),
                    job_role=db_session.get("job_role", "Software Engineer"),
                    experience_level=db_session.get("seniority_level", "Mid-Level"),
                    target_question_count=db_session.get("target_question_count", 5),
                )
                profile = self.resume_service.process_resume("", config.candidate_name)
                plan = self.planner_agent.create_plan(config, profile)
                memory = InterviewMemory(config=config, profile=profile, plan=plan)
                memory.session_id = session_id
                self.sessions[session_id] = memory
            else:
                config = InterviewConfig(candidate_name="Candidate", job_role="Software Engineer", target_question_count=5)
                profile = self.resume_service.process_resume("", config.candidate_name)
                plan = self.planner_agent.create_plan(config, profile)
                memory = InterviewMemory(config=config, profile=profile, plan=plan)
                memory.session_id = session_id
                self.sessions[session_id] = memory

        # Check for explicit termination request
        if candidate_answer.strip().lower() == "end interview":
            logger.info(f"Candidate requested explicit session end for session '{session_id}'")
            return self.end_session(session_id)

        current_q = getattr(memory, "current_question", None)
        if not current_q:
            q1, _ = self.interviewer_agent.generate_next_question(memory)
            current_q = q1

        # 1. Evaluate candidate answer using Groq LLM
        evaluation = self.evaluator_agent.evaluate_answer(
            question=current_q,
            candidate_answer=candidate_answer,
            job_role=memory.config.job_role,
        )

        # 2. Record turn in memory
        turn_record = memory.add_turn(current_q, candidate_answer, evaluation)

        # 3. Update Supabase DB with turn record asynchronously / non-blocking
        try:
            existing_db_session = self.repo.get_session(session_id)
            current_turns = (existing_db_session.get("turn_records") if existing_db_session else []) or []
            current_turns.append({
                "turn_number": turn_record.turn_number,
                "question_text": current_q.text,
                "candidate_answer": candidate_answer,
                "overall_score": getattr(evaluation, "overall", 7.0),
                "technical_accuracy": getattr(evaluation, "technical_accuracy", 7.0),
                "communication_clarity": getattr(evaluation, "clarity", 7.0),
                "problem_solving": getattr(evaluation, "engineering_judgement_score", 7.0),
            })
            self.repo.update_session(session_id, {
                "current_turn": memory.current_turn,
                "turn_records": current_turns,
                "updated_at": "now()",
            })
        except Exception as e:
            logger.warning(f"Non-fatal warning updating session turn in DB: {e}")

        # 4. Check if target question count reached
        if memory.current_turn >= memory.config.target_question_count:
            logger.info(f"Target question count ({memory.config.target_question_count}) reached for session '{session_id}'")
            return self.end_session(session_id)

        # 5. Generate dynamic next question via Groq LLM
        next_q, transition = self.interviewer_agent.generate_next_question(memory)
        memory.current_question = next_q

        return InterviewResponse(
            session_id=session_id,
            is_completed=False,
            current_question=next_q,
            turn_number=memory.current_turn + 1,
            total_target_questions=memory.config.target_question_count,
            transition_phrase=transition,
        )

    def end_session(self, session_id: str) -> InterviewResponse:
        """Ends the interview session, generates performance report, saves report to Supabase DB, and updates session status."""
        memory = self.sessions.get(session_id)
        if not memory:
            db_session = self.repo.get_session(session_id)
            if not db_session:
                raise ValueError(f"Interview session '{session_id}' not found.")
            config = InterviewConfig(candidate_name="Candidate", job_role="Software Engineer", target_question_count=5)
            profile = self.resume_service.process_resume("", config.candidate_name)
            plan = self.planner_agent.create_plan(config, profile)
            memory = InterviewMemory(config=config, profile=profile, plan=plan)
            memory.session_id = session_id

        logger.info(f"Generating final interview report and persisting to Supabase DB for session '{session_id}'")
        report = self.report_agent.generate_report(memory)
        formatted_txt = self.report_agent.generate_formatted_text_report(report)
        closing = self.interviewer_agent.generate_closing_statement(memory)

        # Save to local disk fallback
        json_path, txt_path = save_report_files(
            report_data=report.model_dump(),
            text_report=formatted_txt,
            candidate_name=memory.config.candidate_name,
            reports_dir=settings.REPORTS_DIR,
        )

        # Persist final report directly into Supabase PostgreSQL DB
        report_db_payload = {
            "session_id": session_id,
            "candidate_name": memory.config.candidate_name,
            "job_role": memory.config.job_role,
            "interview_type": memory.config.interview_type.value,
            "difficulty": memory.config.difficulty.value,
            "overall_score": report.overall_score,
            "technical_score": report.technical_score,
            "communication_score": report.communication_score,
            "problem_solving_score": report.problem_solving_score,
            "role_readiness_score": report.role_readiness_score,
            "hire_recommendation": report.hire_recommendation.value,
            "hiring_readiness": report.hiring_readiness,
            "hiring_panel_rationale": report.hiring_panel_rationale,
            "strong_areas": report.strong_areas,
            "areas_for_improvement": report.areas_for_improvement,
            "recommended_topics": report.recommended_topics_to_study,
            "full_report_json": report.model_dump(),
        }
        self.repo.save_report(report_db_payload)

        # Update session status to COMPLETED in Supabase DB
        self.repo.update_session(session_id, {
            "session_status": "COMPLETED",
            "overall_score": report.overall_score,
            "technical_score": report.technical_score,
            "communication_score": report.communication_score,
            "problem_solving_score": report.problem_solving_score,
            "role_readiness_score": report.role_readiness_score,
            "hire_recommendation": report.hire_recommendation.value,
            "updated_at": "now()",
        })

        return InterviewResponse(
            session_id=session_id,
            is_completed=True,
            closing_statement=closing,
            current_question=None,
            turn_number=memory.current_turn,
            total_target_questions=memory.config.target_question_count,
            transition_phrase="Interview completed. Thank you for your responses.",
            report=report,
            report_json_path=str(json_path),
            report_txt_path=str(txt_path),
        )


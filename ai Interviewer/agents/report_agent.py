from models.interview import InterviewReport, TurnRecord
from memory.interview_memory import InterviewMemory
from prompts.report_prompt import REPORT_SYSTEM_PROMPT, REPORT_USER_PROMPT
from services.groq_service import GroqService
from utils.logger import get_logger

logger = get_logger("report_agent")


class ReportGeneratorAgent:
    """Agent responsible for compiling the comprehensive post-interview feedback report."""

    def __init__(self, groq_service: GroqService):
        self.groq_service = groq_service

    def generate_report(self, memory: InterviewMemory) -> InterviewReport:
        """Generates a detailed report with overall scores, category scores, strengths, weaknesses, and question reviews."""
        transcript_lines = []
        for turn in memory.history:
            t_str = (
                f"Question #{turn.turn_number} ({turn.question.question_type.value} - {turn.question.topic}):\n"
                f"Q: \"{turn.question.text}\"\n"
                f"A: \"{turn.candidate_answer}\"\n"
                f"Eval Score: {turn.evaluation.overall}/10 (Accuracy: {turn.evaluation.technical_accuracy}, Clarity: {turn.evaluation.clarity}, Depth: {turn.evaluation.depth})\n"
                f"Strengths: {', '.join(turn.evaluation.strengths)}\n"
                f"Missing: {', '.join(turn.evaluation.missing_points)}\n"
            )
            transcript_lines.append(t_str)

        transcript_data = "\n\n".join(transcript_lines)

        prompt = REPORT_USER_PROMPT.format(
            candidate_name=memory.config.candidate_name,
            job_role=memory.config.job_role,
            transcript_data=transcript_data,
        )

        report = self.groq_service.generate_structured(
            model_class=InterviewReport,
            prompt=prompt,
            system_prompt=REPORT_SYSTEM_PROMPT,
            temperature=0.3,
            max_tokens=4096,
        )

        if not report:
            logger.warning("LLM failed to generate structured report. Compiling mathematical fallback report.")
            return self._fallback_report(memory)

        return report

    def _fallback_report(self, memory: InterviewMemory) -> InterviewReport:
        """Calculates a fallback mathematical report based on stored evaluations."""
        if not memory.history:
            avg_score = 70.0
        else:
            avg_score = (sum(t.evaluation.overall for t in memory.history) / len(memory.history)) * 10.0

        hiring_status = "Developing"
        if avg_score >= 85:
            hiring_status = "Strong Candidate"
        elif avg_score >= 75:
            hiring_status = "Interview Ready"
        elif avg_score >= 60:
            hiring_status = "Developing"
        else:
            hiring_status = "Needs Significant Preparation"

        return InterviewReport(
            candidate_name=memory.config.candidate_name,
            job_role=memory.config.job_role,
            interview_type=memory.config.interview_type.value,
            difficulty=memory.config.difficulty.value,
            overall_score=round(avg_score, 1),
            technical_score=round(avg_score, 1),
            communication_score=round(avg_score - 2, 1),
            problem_solving_score=round(avg_score - 3, 1),
            resume_knowledge_score=round(avg_score, 1),
            clarity_score=round(avg_score - 1, 1),
            role_readiness_score=round(avg_score, 1),
            hiring_readiness=hiring_status,
            summary=f"Completed {len(memory.history)} interview questions for the role of {memory.config.job_role}.",
            strong_areas=list(memory.strong_topics) if memory.strong_topics else ["General role concepts"],
            areas_for_improvement=list(memory.weak_topics) if memory.weak_topics else ["In-depth system design"],
            recommended_topics_to_study=[f"Advanced {memory.config.job_role} patterns"],
            question_reviews=[],
        )

    def generate_formatted_text_report(self, report: InterviewReport) -> str:
        """Formats the InterviewReport object into a clean, human-readable text document."""
        border = "=" * 60
        subborder = "-" * 60

        lines = [
            border,
            f"          CDA AI MOCK INTERVIEW PERFORMANCE REPORT",
            border,
            f" Candidate Name:  {report.candidate_name}",
            f" Target Job Role: {report.job_role}",
            f" Interview Type:  {report.interview_type}",
            f" Difficulty:      {report.difficulty}",
            f" Hiring Status:   {report.hiring_readiness}",
            subborder,
            f" OVERALL PERFORMANCE SCORE: {report.overall_score:.1f} / 100",
            subborder,
            f" CATEGORY BREAKDOWN:",
            f"  • Technical Knowledge: {report.technical_score:.1f} / 100",
            f"  • Communication:       {report.communication_score:.1f} / 100",
            f"  • Problem Solving:     {report.problem_solving_score:.1f} / 100",
            f"  • Resume Knowledge:    {report.resume_knowledge_score:.1f} / 100",
            f"  • Answer Clarity:      {report.clarity_score:.1f} / 100",
            f"  • Role Readiness:      {report.role_readiness_score:.1f} / 100",
            subborder,
            f" EXECUTIVE SUMMARY:",
            f"  {report.summary}",
            subborder,
            f" STRONG AREAS:",
        ]

        for s in report.strong_areas:
            lines.append(f"  [+] {s}")

        lines.extend([subborder, f" AREAS FOR IMPROVEMENT:"])
        for a in report.areas_for_improvement:
            lines.append(f"  [-] {a}")

        lines.extend([subborder, f" TOPICS TO STUDY:"])
        for t in report.recommended_topics_to_study:
            lines.append(f"  [*] {t}")

        if report.question_reviews:
            lines.extend([border, f" DETAILED QUESTION-BY-QUESTION REVIEW", border])
            for rev in report.question_reviews:
                lines.extend([
                    f"\nQuestion #{rev.question_id}: {rev.question}",
                    f"Candidate Answer: {rev.candidate_answer}",
                    f"Score: {rev.score:.1f}/10",
                    f"What Was Good: {', '.join(rev.what_was_good) if rev.what_was_good else 'N/A'}",
                    f"What Was Missing: {', '.join(rev.what_was_missing) if rev.what_was_missing else 'N/A'}",
                    f"How To Improve: {rev.how_to_improve}",
                    f"Example Better Answer:\n{rev.example_better_answer}",
                    subborder,
                ])

        lines.append(border)
        return "\n".join(lines)

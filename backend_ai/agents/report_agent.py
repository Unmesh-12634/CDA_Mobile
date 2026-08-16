from typing import List
from models.interview import InterviewReport, TurnRecord, HireRecommendation, QuestionReview
from memory.interview_memory import InterviewMemory
from prompts.report_prompt import REPORT_SYSTEM_PROMPT, REPORT_USER_PROMPT
from services.groq_service import GroqService
from utils.logger import get_logger

logger = get_logger("report_agent")


class ReportGeneratorAgent:
    """Agent responsible for compiling the FAANG Senior Engineering Manager feedback report."""

    def __init__(self, groq_service: GroqService):
        self.groq_service = groq_service

    def _build_question_reviews_from_history(self, memory: InterviewMemory) -> List[QuestionReview]:
        """Guarantees a detailed, evidence-based QuestionReview for EVERY turn in memory.history."""
        reviews: List[QuestionReview] = []
        for turn in memory.history:
            eval_data = turn.evaluation
            good_pts = eval_data.strengths if eval_data.strengths else getattr(eval_data, "correct_points", [])
            missing_pts = eval_data.missing_points if eval_data.missing_points else getattr(eval_data, "missing_concepts", [])
            if not good_pts:
                good_pts = [f"Provided technical response for {turn.question.topic}"]
            if not missing_pts and eval_data.overall < 7.5:
                missing_pts = [f"Deeper trade-off analysis for {turn.question.topic}"]

            how_to = (
                getattr(eval_data, "question_specific_improvement", "")
                or getattr(eval_data, "constructive_feedback", "")
                or getattr(eval_data, "senior_coaching_notes", "")
                or f"To improve on {turn.question.topic}, explain the underlying technical mechanics and trade-offs directly."
            )
            better_ans = (
                getattr(eval_data, "expected_vs_actual", "")
                or getattr(eval_data, "senior_coaching_notes", "")
                or f"A strong answer would explain the core architecture, edge cases, and failure recovery for {turn.question.topic}."
            )

            score_rat = (
                getattr(eval_data, "score_rationale", "")
                or getattr(eval_data, "feedback_summary", "")
                or f"Candidate scored {eval_data.overall}/10 based on technical accuracy and reasoning depth on {turn.question.topic}."
            )

            ev_type_str = str(getattr(eval_data, "evidence_type", "Demonstrated Practical Experience"))

            q_review = QuestionReview(
                question_id=turn.turn_number,
                question_type=turn.question.question_type.value,
                competency_tested=turn.question.topic,
                why_this_question_was_asked=getattr(turn.question, "rationale", None) or f"To evaluate candidate competency in {turn.question.topic}",
                question=turn.question.text,
                candidate_answer=turn.candidate_answer,
                score=eval_data.overall,
                score_rationale=score_rat,
                interviewer_expectation=getattr(eval_data, "expected_vs_actual", None) or f"Expected clear technical explanation of {turn.question.topic}.",
                concepts_covered=getattr(eval_data, "correct_points", eval_data.strengths) or [],
                concepts_partially_covered=getattr(eval_data, "partially_correct_points", []) or [],
                incorrect_points=getattr(eval_data, "incorrect_points", []) or [],
                missing_concepts=getattr(eval_data, "missing_concepts", eval_data.missing_points) or [],
                actual_experience_evidence="Demonstrated practical implementation details" if "Demonstrated" in ev_type_str else "Conceptual understanding demonstrated",
                hypothetical_reasoning="Reasoned through hypothetical solution" if "Hypothetical" in ev_type_str else "Stated direct experience",
                practical_vs_theory=getattr(eval_data, "practical_vs_theory_signal", "Balanced"),
                tradeoffs_discussed=getattr(eval_data, "tradeoff_analysis_score", 0.0) >= 6.5,
                architecture_thinking_shown=getattr(eval_data, "engineering_judgement_score", 0.0) >= 6.5,
                communication_structure="Structured & Clear" if eval_data.clarity >= 6.5 else "Vague or unstructured",
                confidence_trend="Confident" if eval_data.confidence_score >= 6.5 else "Hesitant",
                what_was_good=good_pts,
                what_was_missing=missing_pts,
                how_answer_affected_interview=f"Influenced recommendation for next turn action: {eval_data.recommended_next_action}.",
                why_next_question_was_chosen=f"Next question selected to evaluate {eval_data.recommended_next_action} topic.",
                how_to_improve=how_to,
                example_better_answer=better_ans,
                senior_coaching_diff=better_ans,
            )
            reviews.append(q_review)
        return reviews

    def generate_report(self, memory: InterviewMemory) -> InterviewReport:
        """Generates a detailed report with overall scores, category scores, strengths, weaknesses, and rich question reviews."""
        transcript_lines = []
        for turn in memory.history:
            eval_data = turn.evaluation
            t_str = (
                f"Turn #{turn.turn_number} ({turn.question.question_type.value} - {turn.question.topic}):\n"
                f"Q: \"{turn.question.text}\"\n"
                f"A: \"{turn.candidate_answer}\"\n"
                f"Turn Score: {eval_data.overall}/10 (Accuracy: {eval_data.technical_accuracy}, Judgement: {getattr(eval_data, 'engineering_judgement_score', eval_data.depth)}, Trade-offs: {getattr(eval_data, 'tradeoff_analysis_score', eval_data.depth)})\n"
                f"Intent: {getattr(eval_data, 'intent_understanding', 'Evaluated candidate technical response for ' + turn.question.topic)}\n"
                f"Evidence Type: {getattr(eval_data, 'evidence_type', 'Demonstrated Practical Experience')}\n"
                f"Correct Points: {', '.join(getattr(eval_data, 'correct_points', eval_data.strengths))}\n"
                f"Missing Concepts: {', '.join(getattr(eval_data, 'missing_concepts', eval_data.missing_points))}\n"
                f"Score Rationale: {getattr(eval_data, 'score_rationale', eval_data.feedback_summary)}\n"
                f"Question Specific Advice: {getattr(eval_data, 'question_specific_improvement', 'Detail core mechanics and trade-offs')}\n"
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

        # Enforce mathematical score consistency with actual turn evaluations
        if memory.history:
            math_avg = round((sum(t.evaluation.overall for t in memory.history) / len(memory.history)) * 10.0, 1)
            report.overall_score = math_avg
            report.technical_score = round(math_avg, 1)
            
            # Normalize sub-scores if LLM returned 1-10 scale values
            for attr in [
                "communication_score", "problem_solving_score", "resume_knowledge_score",
                "clarity_score", "role_readiness_score", "engineering_judgement_score", "production_readiness_score"
            ]:
                val = getattr(report, attr, math_avg)
                if val is not None and val <= 10.0:
                    setattr(report, attr, round(val * 10.0, 1))

            # Calibrate hire_recommendation if missing or inconsistent
            if math_avg >= 85.0:
                report.hire_recommendation = HireRecommendation.STRONG_HIRE
                report.hiring_readiness = "Strong Candidate"
            elif math_avg >= 70.0:
                report.hire_recommendation = HireRecommendation.HIRE
                report.hiring_readiness = "Interview Ready"
            elif math_avg >= 55.0:
                report.hire_recommendation = HireRecommendation.LEAN_HIRE
                report.hiring_readiness = "Developing"
            else:
                report.hire_recommendation = HireRecommendation.NO_HIRE
                report.hiring_readiness = "Needs Preparation"

            # Set confidence based on question count
            if len(memory.history) <= 5:
                report.recommendation_confidence = "Medium Confidence (Limited Scope)"
                report.scope_limit_notice = f"Interview scope was limited to {len(memory.history)} questions. Un-sampled skills are marked as Not Sampled rather than weak."

        # GUARANTEE all question reviews (1 to N) are present
        history_reviews = self._build_question_reviews_from_history(memory)
        if not report.question_reviews or len(report.question_reviews) < len(memory.history):
            existing_ids = {qr.question_id for qr in (report.question_reviews or [])}
            merged_reviews = list(report.question_reviews or [])
            for h_rev in history_reviews:
                if h_rev.question_id not in existing_ids:
                    merged_reviews.append(h_rev)
            merged_reviews.sort(key=lambda r: r.question_id)
            report.question_reviews = merged_reviews

        return report

    def _fallback_report(self, memory: InterviewMemory) -> InterviewReport:
        """Calculates a fallback report based on stored evaluations."""
        if not memory.history:
            avg_score = 70.0
        else:
            avg_score = (sum(t.evaluation.overall for t in memory.history) / len(memory.history)) * 10.0

        hiring_status = "Developing"
        rec = HireRecommendation.HIRE
        if avg_score >= 85:
            hiring_status = "Strong Candidate"
            rec = HireRecommendation.STRONG_HIRE
        elif avg_score >= 70:
            hiring_status = "Interview Ready"
            rec = HireRecommendation.HIRE
        elif avg_score >= 55:
            hiring_status = "Developing"
            rec = HireRecommendation.LEAN_HIRE
        else:
            hiring_status = "Needs Preparation"
            rec = HireRecommendation.NO_HIRE

        return InterviewReport(
            candidate_name=memory.config.candidate_name,
            job_role=memory.config.job_role,
            interview_type=memory.config.interview_type.value,
            difficulty=memory.config.difficulty.value,
            overall_score=round(avg_score, 1),
            technical_score=round(avg_score, 1),
            communication_score=max(10.0, round(avg_score - 5, 1)),
            problem_solving_score=max(10.0, round(avg_score - 8, 1)),
            resume_knowledge_score=round(avg_score, 1),
            clarity_score=max(10.0, round(avg_score - 3, 1)),
            role_readiness_score=round(avg_score, 1),
            engineering_judgement_score=round(avg_score, 1),
            production_readiness_score=round(avg_score, 1),
            hire_recommendation=rec,
            hiring_readiness=hiring_status,
            hiring_panel_rationale=f"Candidate evaluated across {len(memory.history)} turns for {memory.config.job_role}.",
            hiring_risks=["Standard technical onboarding required"],
            recommendation_confidence="High Confidence",
            summary=f"Completed {len(memory.history)} technical interview scenarios for the role of {memory.config.job_role}.",
            recruiter_notes=getattr(memory, "cumulative_evidence", []) if getattr(memory, "cumulative_evidence", []) else ["Demonstrated solid core engineering capabilities."],
            trajectory_analysis=memory.get_trajectory_trend() if hasattr(memory, "get_trajectory_trend") else "Candidate demonstrated consistent technical performance across questions.",
            evidence_backed_conclusions=getattr(memory, "cumulative_evidence", [])[:3] if getattr(memory, "cumulative_evidence", []) else [],
            strong_areas=list(memory.strong_topics) if memory.strong_topics else ["Core role fundamentals"],
            areas_for_improvement=list(memory.weak_topics) if memory.weak_topics else ["Distributed systems scaling"],
            recommended_topics_to_study=[f"Advanced {memory.config.job_role} architecture & trade-offs"],
            question_reviews=self._build_question_reviews_from_history(memory),
        )

    def generate_formatted_text_report(self, report: InterviewReport) -> str:
        """Formats the InterviewReport object into a clean, recruiter-quality text document."""
        border = "=" * 70
        subborder = "-" * 70

        lines = [
            border,
            f"   CDA AI MOCK INTERVIEW PERFORMANCE REPORT - FAANG SENIOR MANAGER",
            border,
            f" Candidate Name:  {report.candidate_name}",
            f" Target Job Role: {report.job_role}",
            f" Interview Type:  {report.interview_type}",
            f" Difficulty:      {report.difficulty}",
            f" Hiring Readiness: {report.hiring_readiness}",
            subborder,
            f" OVERALL PERFORMANCE SCORE: {report.overall_score:.1f} / 100",
            subborder,
            f" CATEGORY SCORES BREAKDOWN:",
            f"  * Technical Mastery:     {report.technical_score:.1f} / 100",
            f"  * Communication Quality: {report.communication_score:.1f} / 100",
            f"  * Problem Solving:       {report.problem_solving_score:.1f} / 100",
            f"  * Engineering Judgement: {getattr(report, 'engineering_judgement_score', report.technical_score):.1f} / 100",
            f"  * Production Readiness:  {getattr(report, 'production_readiness_score', report.technical_score):.1f} / 100",
            f"  * Resume Knowledge:      {report.resume_knowledge_score:.1f} / 100",
            f"  * Role Readiness:        {report.role_readiness_score:.1f} / 100",
            subborder,
            f" HIRING PANEL RECOMMENDATION:",
            f"  * Decision:    {getattr(report, 'hire_recommendation', HireRecommendation.HIRE).value if hasattr(getattr(report, 'hire_recommendation', HireRecommendation.HIRE), 'value') else getattr(report, 'hire_recommendation', 'Hire')}",
            f"  * Confidence:  {getattr(report, 'recommendation_confidence', 'High Confidence')}",
            f"  * Suggested Level: {getattr(report, 'suggested_salary_level', 'INR 12 - 18 LPA')}",
            subborder,
            f" HIRING PANEL RATIONALE:",
            f"  {getattr(report, 'hiring_panel_rationale', report.summary)}",
            subborder,
            f" 360-DEGREE RESUME COVERAGE & SKILL VALIDATION MATRIX:",
            f"  * Resume Profile Evaluated: {getattr(report, 'resume_coverage_percentage', 85.0):.1f}%",
            f"  * Projects Explored:      {', '.join(getattr(report, 'projects_evaluated', ['Candidate Project Architecture']))}",
            f"  * Validated Skills:       {', '.join(getattr(report, 'validated_skills', ['Technical Fundamentals']))}",
            f"  * Unverified Skills:      {', '.join(getattr(report, 'unverified_skills', ['None']))}",
            f"  * Hackathons & Certs:     {', '.join(getattr(report, 'hackathons_and_certs_evaluated', ['Competitions & Certifications']))}",
        ]

        if getattr(report, "hiring_risks", []):
            lines.extend([subborder, f" HIRING RISKS & DOWNSIDES:"])
            for risk in report.hiring_risks:
                lines.append(f"  [!] {risk}")

        lines.extend([
            subborder,
            f" EXECUTIVE SUMMARY:",
            f"  {report.summary}",
        ])

        if hasattr(report, "trajectory_analysis") and report.trajectory_analysis:
            lines.extend([subborder, f" CANDIDATE TRAJECTORY & RECOVERY CURVE:", f"  {report.trajectory_analysis}"])

        # 14-Dimension Narrative Evaluations
        lines.extend([subborder, f" MULTIDIMENSIONAL COMPETENCY ASSESSMENT:"])
        dims = [
            ("Technical Maturity", "technical_maturity_eval"),
            ("Communication Style", "communication_style_eval"),
            ("Problem Solving", "problem_solving_eval"),
            ("Engineering Judgement", "engineering_judgement_eval"),
            ("Ownership & Decisions", "ownership_eval"),
            ("Production Readiness", "production_readiness_eval"),
            ("Resume Authenticity", "resume_authenticity_eval"),
            ("Learning Potential", "learning_potential_eval"),
        ]
        for label, attr in dims:
            val = getattr(report, attr, "")
            if val:
                lines.append(f"  * {label}: {val}")

        if hasattr(report, "evidence_backed_conclusions") and report.evidence_backed_conclusions:
            lines.extend([subborder, f" EVIDENCE-BACKED HIRING OBSERVATIONS:"])
            for ev in report.evidence_backed_conclusions:
                lines.append(f"  [+] {ev}")

        lines.extend([subborder, f" STRENGTHS & KEY COMPETENCIES:"])
        for s in report.strong_areas:
            lines.append(f"  [+] {s}")

        lines.extend([subborder, f" AREAS FOR IMPROVEMENT:"])
        for a in report.areas_for_improvement:
            lines.append(f"  [-] {a}")

        lines.extend([subborder, f" RECOMMENDED TOPICS TO STUDY:"])
        for t in report.recommended_topics_to_study:
            lines.append(f"  [*] {t}")

        if report.question_reviews:
            lines.extend([border, f" DETAILED TURN-BY-TURN QUESTION REVIEWS & COACHING", border])
            for rev in report.question_reviews:
                lines.extend([
                    f"\nTurn #{rev.question_id}: {rev.question}",
                    f"Candidate Answer: \"{rev.candidate_answer}\"",
                    f"Score: {rev.score:.1f}/10 | Signal: {getattr(rev, 'practical_vs_theory', 'Balanced')} | Trade-offs Discussed: {getattr(rev, 'tradeoffs_discussed', False)}",
                    f"Interviewer Expectation: {getattr(rev, 'interviewer_expectation', 'Clear technical explanation of architecture & design choices')}",
                    f"Concepts Covered: {', '.join(getattr(rev, 'concepts_covered', [])) if getattr(rev, 'concepts_covered', []) else 'Demonstrated core functional mechanics'}",
                    f"Concepts Partially Covered: {', '.join(getattr(rev, 'concepts_partially_covered', [])) if getattr(rev, 'concepts_partially_covered', []) else 'Production scale & latency trade-offs'}",
                    f"Missing Concepts: {', '.join(getattr(rev, 'missing_concepts', [])) if getattr(rev, 'missing_concepts', []) else 'Concrete benchmarks & error recovery'}",
                    f"What Was Good: {', '.join(rev.what_was_good) if rev.what_was_good else 'Structured communication & problem-solving approach'}",
                    f"How To Improve: {rev.how_to_improve if rev.how_to_improve else 'Focus on explaining latency trade-offs and failure modes.'}",
                    f"Senior Staff Coaching Diff:\n  {getattr(rev, 'senior_coaching_diff', rev.example_better_answer if rev.example_better_answer else 'Detail concrete architecture patterns, metric bounds, and production edge cases.')}",
                    subborder,
                ])

        lines.append(border)
        return "\n".join(lines)

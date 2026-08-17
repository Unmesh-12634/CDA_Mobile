package com.cda.backend.dao;

import com.cda.backend.model.UserAnalytics;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public class AnalyticsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public UserAnalytics getAnalytics(String email) {
        UserAnalytics a = new UserAnalytics();

        // ── Interview Stats ─────────────────────────────────────
        try {
            Integer total = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM public.ai_interview_reports WHERE candidate_email = ?",
                Integer.class, email);
            a.setTotalInterviews(total != null ? total : 0);
        } catch (Exception e) { a.setTotalInterviews(0); }

        try {
            Double avg = jdbcTemplate.queryForObject(
                "SELECT COALESCE(AVG(overall_score), 0) FROM public.ai_interview_reports WHERE candidate_email = ?",
                Double.class, email);
            a.setAvgInterviewScore(avg != null ? Math.round(avg * 10.0) / 10.0 : 0.0);
        } catch (Exception e) { a.setAvgInterviewScore(0.0); }

        try {
            Double best = jdbcTemplate.queryForObject(
                "SELECT COALESCE(MAX(overall_score), 0) FROM public.ai_interview_reports WHERE candidate_email = ?",
                Double.class, email);
            a.setBestInterviewScore(best != null ? Math.round(best * 10.0) / 10.0 : 0.0);
        } catch (Exception e) { a.setBestInterviewScore(0.0); }

        try {
            String lastDate = jdbcTemplate.queryForObject(
                "SELECT TO_CHAR(MAX(created_at), 'DD Mon YYYY') FROM public.ai_interview_reports WHERE candidate_email = ?",
                String.class, email);
            a.setLastInterviewDate(lastDate != null ? lastDate : "No interviews yet");
        } catch (Exception e) { a.setLastInterviewDate("No interviews yet"); }

        // ── Learning Streak ──────────────────────────────────────
        try {
            List<Map<String, Object>> goalRows = jdbcTemplate.queryForList(
                "SELECT streak_count, completed_days_count, total_hours_learned FROM public.user_learning_goals WHERE user_email = ?",
                email);
            if (!goalRows.isEmpty()) {
                Map<String, Object> row = goalRows.get(0);
                a.setCurrentStreak(row.get("streak_count") != null ? ((Number) row.get("streak_count")).intValue() : 0);
                a.setCompletedDaysCount(row.get("completed_days_count") != null ? ((Number) row.get("completed_days_count")).intValue() : 0);
                a.setTotalHoursLearned(row.get("total_hours_learned") != null ? ((Number) row.get("total_hours_learned")).doubleValue() : 0.0);
            }
        } catch (Exception e) {
            a.setCurrentStreak(0);
            a.setCompletedDaysCount(0);
            a.setTotalHoursLearned(0.0);
        }

        try {
            List<Map<String, Object>> userRows = jdbcTemplate.queryForList(
                "SELECT COALESCE(longest_streak, 0) as longest_streak FROM public.users WHERE email = ?", email);
            if (!userRows.isEmpty()) {
                a.setLongestStreak(((Number) userRows.get(0).get("longest_streak")).intValue());
            }
        } catch (Exception e) { a.setLongestStreak(a.getCurrentStreak()); }

        // ── Job Activity ─────────────────────────────────────────
        try {
            Integer apps = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM public.job_applications WHERE user_email = ?",
                Integer.class, email);
            a.setTotalApplications(apps != null ? apps : 0);
        } catch (Exception e) { a.setTotalApplications(0); }

        try {
            Integer saved = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM public.saved_jobs WHERE user_email = ?",
                Integer.class, email);
            a.setSavedJobsCount(saved != null ? saved : 0);
        } catch (Exception e) { a.setSavedJobsCount(0); }

        // ── Quiz Stats ───────────────────────────────────────────
        try {
            Integer quizTotal = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM public.quiz_results WHERE user_email = ?",
                Integer.class, email);
            a.setTotalQuizzes(quizTotal != null ? quizTotal : 0);
        } catch (Exception e) { a.setTotalQuizzes(0); }

        try {
            Double avgQuiz = jdbcTemplate.queryForObject(
                "SELECT COALESCE(AVG(score), 0) FROM public.quiz_results WHERE user_email = ?",
                Double.class, email);
            a.setAvgQuizScore(avgQuiz != null ? Math.round(avgQuiz * 10.0) / 10.0 : 0.0);
        } catch (Exception e) { a.setAvgQuizScore(0.0); }

        try {
            Integer bestQuiz = jdbcTemplate.queryForObject(
                "SELECT COALESCE(MAX(score), 0) FROM public.quiz_results WHERE user_email = ?",
                Integer.class, email);
            a.setBestQuizScore(bestQuiz != null ? bestQuiz : 0);
        } catch (Exception e) { a.setBestQuizScore(0); }

        // ── Profile ──────────────────────────────────────────────
        try {
            List<Map<String, Object>> profileRows = jdbcTemplate.queryForList(
                "SELECT COALESCE(profile_strength_score, 0) as pss, target_role FROM public.users WHERE email = ?",
                email);
            if (!profileRows.isEmpty()) {
                Map<String, Object> row = profileRows.get(0);
                a.setProfileStrengthScore(row.get("pss") != null ? ((Number) row.get("pss")).intValue() : 0);
                a.setTargetRole(row.get("target_role") != null ? row.get("target_role").toString() : null);
            }
        } catch (Exception e) {
            a.setProfileStrengthScore(0);
            a.setTargetRole(null);
        }

        return a;
    }
}

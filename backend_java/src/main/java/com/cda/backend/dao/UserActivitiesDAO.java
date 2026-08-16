package com.cda.backend.dao;

import com.cda.backend.model.UserActivity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

@Repository
public class UserActivitiesDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<UserActivity> findRecentActivitiesByUserEmail(String email) {
        List<UserActivity> list = new ArrayList<>();
        if (email == null || email.trim().isEmpty()) {
            return list;
        }

        // 1. Fetch recent job applications
        try {
            String appSql = "SELECT id, job_id, resume_url, status, created_at FROM public.job_applications WHERE user_email = ? ORDER BY created_at DESC LIMIT 10";
            jdbcTemplate.query(appSql, (rs) -> {
                String id = rs.getString("id");
                String status = rs.getString("status");
                Timestamp ts = rs.getTimestamp("created_at");
                LocalDateTime ldt = ts != null ? ts.toLocalDateTime() : LocalDateTime.now();
                
                UserActivity a = new UserActivity(
                    id,
                    email,
                    "JOB_APPLIED",
                    "Submitted Job Application",
                    "Status: " + (status != null ? status : "Applied"),
                    "/application-tracker",
                    "work",
                    ldt
                );
                list.add(a);
            }, email);
        } catch (Exception e) {
            // ignore if table query fails
        }

        // 2. Fetch recent AI interview reports
        try {
            String repSql = "SELECT id, candidate_name, overall_score, target_role, created_at FROM public.ai_interview_reports WHERE candidate_email = ? ORDER BY created_at DESC LIMIT 10";
            jdbcTemplate.query(repSql, (rs) -> {
                String id = rs.getString("id");
                double score = rs.getDouble("overall_score");
                String role = rs.getString("target_role");
                Timestamp ts = rs.getTimestamp("created_at");
                LocalDateTime ldt = ts != null ? ts.toLocalDateTime() : LocalDateTime.now();

                UserActivity a = new UserActivity(
                    id,
                    email,
                    "INTERVIEW_COMPLETED",
                    "Completed " + (role != null ? role : "Tech") + " AI Mock",
                    "Overall Score: " + Math.round(score) + "%",
                    "/interview/reports",
                    "interview",
                    ldt
                );
                list.add(a);
            }, email);
        } catch (Exception e) {
            // ignore
        }

        // 3. Fetch recent saved reels
        try {
            String reelSql = "SELECT id, reel_id, created_at FROM public.saved_reels WHERE user_email = ? ORDER BY created_at DESC LIMIT 5";
            jdbcTemplate.query(reelSql, (rs) -> {
                String id = rs.getString("id");
                Timestamp ts = rs.getTimestamp("created_at");
                LocalDateTime ldt = ts != null ? ts.toLocalDateTime() : LocalDateTime.now();

                UserActivity a = new UserActivity(
                    id,
                    email,
                    "REEL_SAVED",
                    "Bookmarked Career Reel",
                    "Added to Saved Video Library",
                    "/saved-reels",
                    "play",
                    ldt
                );
                list.add(a);
            }, email);
        } catch (Exception e) {
            // ignore
        }

        // 4. Fetch recent saved jobs
        try {
            String jobSql = "SELECT id, job_id, created_at FROM public.saved_jobs WHERE user_email = ? ORDER BY created_at DESC LIMIT 5";
            jdbcTemplate.query(jobSql, (rs) -> {
                String id = rs.getString("id");
                Timestamp ts = rs.getTimestamp("created_at");
                LocalDateTime ldt = ts != null ? ts.toLocalDateTime() : LocalDateTime.now();

                UserActivity a = new UserActivity(
                    id,
                    email,
                    "JOB_SAVED",
                    "Bookmarked Job Opening",
                    "Saved for future application",
                    "/saved-jobs",
                    "work",
                    ldt
                );
                list.add(a);
            }, email);
        } catch (Exception e) {
            // ignore
        }

        // Sort by created_at DESC
        list.sort(Comparator.comparing(UserActivity::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())));

        return list.size() > 10 ? list.subList(0, 10) : list;
    }
}

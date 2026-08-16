package com.cda.backend.dao;

import com.cda.backend.model.InterviewReport;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Array;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Repository
public class InterviewReportDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private static final RowMapper<InterviewReport> REPORT_MAPPER = new RowMapper<InterviewReport>() {
        @Override
        public InterviewReport mapRow(ResultSet rs, int rowNum) throws SQLException {
            InterviewReport r = new InterviewReport();
            r.setId(rs.getString("id"));
            r.setUserId(rs.getString("user_id"));
            r.setTargetRole(rs.getString("target_role"));
            r.setOverallScore(rs.getDouble("overall_score"));
            r.setFeedbackSummary(rs.getString("feedback_summary"));
            r.setDurationSeconds(rs.getInt("duration_seconds"));
            r.setCreatedAt(rs.getString("created_at"));

            Array strArr = rs.getArray("strengths");
            if (strArr != null) {
                r.setStrengths(Arrays.asList((String[]) strArr.getArray()));
            } else {
                r.setStrengths(Collections.emptyList());
            }

            Array impArr = rs.getArray("improvements");
            if (impArr != null) {
                r.setImprovements(Arrays.asList((String[]) impArr.getArray()));
            } else {
                r.setImprovements(Collections.emptyList());
            }

            String qaJson = rs.getString("detailed_qa_json");
            if (qaJson != null && !qaJson.trim().isEmpty()) {
                try {
                    Map<String, Object> map = OBJECT_MAPPER.readValue(qaJson, Map.class);
                    r.setDetailedQaJson(map);
                } catch (Exception ignored) {}
            }

            return r;
        }
    };

    public List<InterviewReport> findReportsByEmail(String email) {
        String sql = "SELECT r.* FROM public.ai_interview_reports r " +
                "JOIN public.users u ON r.user_id = u.id " +
                "WHERE u.email = ? " +
                "ORDER BY r.created_at DESC";
        List<InterviewReport> list = jdbcTemplate.query(sql, REPORT_MAPPER, email);
        if (list.isEmpty()) {
            // Fallback by latest created
            String allSql = "SELECT * FROM public.ai_interview_reports ORDER BY created_at DESC LIMIT 20";
            return jdbcTemplate.query(allSql, REPORT_MAPPER);
        }
        return list;
    }

    public boolean saveReport(String email, String targetRole, double overallScore, String feedbackSummary, List<String> strengths, List<String> improvements, String detailedQaJson, int durationSeconds) {
        try {
            String findUserSql = "SELECT id FROM public.users WHERE email = ? LIMIT 1";
            List<String> userIds = jdbcTemplate.query(findUserSql, (rs, rowNum) -> rs.getString("id"), email);
            String userId = userIds.isEmpty() ? "7e3f690f-38b7-4bfa-af4f-5afa4b79428f" : userIds.get(0);

            String insertSql = "INSERT INTO public.ai_interview_reports " +
                    "(id, user_id, target_role, overall_score, feedback_summary, detailed_qa_json, duration_seconds, completed_at, created_at) " +
                    "VALUES (gen_random_uuid(), ?::uuid, ?, ?, ?, ?::jsonb, ?, NOW(), NOW())";
            
            int rows = jdbcTemplate.update(insertSql, userId, targetRole, overallScore, feedbackSummary, detailedQaJson, durationSeconds);
            return rows > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}

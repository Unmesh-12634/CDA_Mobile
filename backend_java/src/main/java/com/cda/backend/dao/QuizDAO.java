package com.cda.backend.dao;

import com.cda.backend.model.QuizResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;

@Repository
public class QuizDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final RowMapper<QuizResult> QUIZ_MAPPER = new RowMapper<QuizResult>() {
        @Override
        public QuizResult mapRow(ResultSet rs, int rowNum) throws SQLException {
            QuizResult q = new QuizResult();
            q.setId(rs.getString("id"));
            q.setUserEmail(rs.getString("user_email"));
            q.setScore(rs.getInt("score"));
            q.setCorrectCount(rs.getInt("correct_count"));
            q.setTotalQuestions(rs.getInt("total_questions"));
            q.setCategory(rs.getString("category"));
            q.setSkillFocus(rs.getString("skill_focus"));
            q.setCompletedAt(rs.getString("completed_at"));
            return q;
        }
    };

    public boolean saveResult(String email, int score, int correctCount, int totalQuestions,
                              String category, String skillFocus) {
        try {
            String sql = "INSERT INTO public.quiz_results (user_email, score, correct_count, total_questions, category, skill_focus) " +
                         "VALUES (?, ?, ?, ?, ?, ?)";
            jdbcTemplate.update(sql, email, score, correctCount, totalQuestions, category, skillFocus);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public List<QuizResult> fetchHistory(String email, int limit) {
        try {
            String sql = "SELECT * FROM public.quiz_results WHERE user_email = ? " +
                         "ORDER BY completed_at DESC LIMIT ?";
            return jdbcTemplate.query(sql, QUIZ_MAPPER, email, limit);
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    public double getAvgScore(String email) {
        try {
            String sql = "SELECT COALESCE(AVG(score), 0) FROM public.quiz_results WHERE user_email = ?";
            return jdbcTemplate.queryForObject(sql, Double.class, email);
        } catch (Exception e) {
            return 0.0;
        }
    }

    public int getTotalCount(String email) {
        try {
            String sql = "SELECT COUNT(*) FROM public.quiz_results WHERE user_email = ?";
            Integer count = jdbcTemplate.queryForObject(sql, Integer.class, email);
            return count != null ? count : 0;
        } catch (Exception e) {
            return 0;
        }
    }

    public int getBestScore(String email) {
        try {
            String sql = "SELECT COALESCE(MAX(score), 0) FROM public.quiz_results WHERE user_email = ?";
            Integer max = jdbcTemplate.queryForObject(sql, Integer.class, email);
            return max != null ? max : 0;
        } catch (Exception e) {
            return 0;
        }
    }
}

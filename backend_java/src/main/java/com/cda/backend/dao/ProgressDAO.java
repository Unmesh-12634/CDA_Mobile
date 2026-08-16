package com.cda.backend.dao;

import com.cda.backend.model.UserProgress;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ProgressDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private final ObjectMapper mapper = new ObjectMapper();

    public UserProgress getProgressByEmail(String email) {
        String sql = "SELECT current_streak, weekly_days_completed, total_study_minutes, last_active_date FROM public.users WHERE email = ?";
        return jdbcTemplate.query(sql, rs -> {
            if (rs.next()) {
                int streak = rs.getInt("current_streak");
                int minutes = rs.getInt("total_study_minutes");
                String lastActive = rs.getString("last_active_date");
                String jsonb = rs.getString("weekly_days_completed");

                List<Boolean> days = new ArrayList<>();
                try {
                    if (jsonb != null) {
                        days = mapper.readValue(jsonb, mapper.getTypeFactory().constructCollectionType(List.class, Boolean.class));
                    }
                } catch (Exception ignored) {}

                while (days.size() < 7) {
                    days.add(false);
                }

                return new UserProgress(streak, days, minutes, lastActive);
            }
            return null;
        }, email);
    }

    public boolean completeToday(String email) {
        UserProgress current = getProgressByEmail(email);
        List<Boolean> days = current != null ? current.getWeeklyDaysCompleted() : new ArrayList<>();
        while (days.size() < 7) {
            days.add(false);
        }

        int dayOfWeek = LocalDate.now().getDayOfWeek().getValue() - 1; // 0 = Monday, 6 = Sunday
        if (dayOfWeek >= 0 && dayOfWeek < 7) {
            days.set(dayOfWeek, true);
        }

        int newStreak = current != null ? (current.getStreakCount() + 1) : 1;
        int newMinutes = current != null ? (current.getTotalStudyMinutes() + 30) : 30;

        try {
            String json = mapper.writeValueAsString(days);
            String sql = "UPDATE public.users SET current_streak = ?, weekly_days_completed = ?::jsonb, total_study_minutes = ?, last_active_date = CURRENT_DATE WHERE email = ?";
            int rows = jdbcTemplate.update(sql, newStreak, json, newMinutes, email);
            return rows > 0;
        } catch (Exception e) {
            return false;
        }
    }
}

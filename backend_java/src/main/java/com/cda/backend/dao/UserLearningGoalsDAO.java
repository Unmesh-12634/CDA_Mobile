package com.cda.backend.dao;

import com.cda.backend.model.UserLearningGoal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Repository
public class UserLearningGoalsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public UserLearningGoal getLearningGoal(String email) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email.trim() : "";
        LocalDate today = LocalDate.now(); // 12:00 AM calendar day boundary
        if (targetEmail.isEmpty()) {
            return new UserLearningGoal("", 7, 0, List.of(false,false,false,false,false,false,false), 0.0, 0, today.toString(), "Start your learning journey today!");
        }
        
        // 1. Try to read from public.user_learning_goals if table exists
        try {
            String sql = "SELECT target_days, completed_days_count, total_hours_learned, streak_count, last_active_date, next_goal_suggestion FROM public.user_learning_goals WHERE user_email = ? LIMIT 1";
            return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> {
                int targetDays = rs.getInt("target_days");
                int completedDays = rs.getInt("completed_days_count");
                double hours = rs.getDouble("total_hours_learned");
                int rawStreak = rs.getInt("streak_count");
                String lastDateStr = rs.getString("last_active_date");
                String suggestion = rs.getString("next_goal_suggestion");

                int activeStreak = rawStreak;
                if (lastDateStr != null && !lastDateStr.isEmpty()) {
                    try {
                        LocalDate lastDate = LocalDate.parse(lastDateStr.split("T")[0]);
                        long daysBetween = ChronoUnit.DAYS.between(lastDate, today);
                        if (daysBetween > 1) {
                            // User missed at least 1 whole calendar day (past 12:00 AM)
                            activeStreak = 0;
                        }
                    } catch (Exception ignored) {}
                }
                
                List<Boolean> weekly = new ArrayList<>();
                for (int i = 0; i < 7; i++) {
                    weekly.add(i < completedDays);
                }
                
                return new UserLearningGoal(targetEmail, targetDays, completedDays, weekly, hours, activeStreak, lastDateStr, suggestion);
            }, targetEmail);
        } catch (Exception e) {
            // Fallback: Dynamically compute from database activity
            int interviewCount = 0;
            try {
                interviewCount = jdbcTemplate.queryForObject("SELECT count(*) FROM public.ai_interview_reports WHERE candidate_email = ?", Integer.class, targetEmail);
            } catch (Exception ex) {
                interviewCount = 1;
            }

            int appCount = 0;
            try {
                appCount = jdbcTemplate.queryForObject("SELECT count(*) FROM public.job_applications WHERE user_email = ?", Integer.class, targetEmail);
            } catch (Exception ex) {
                appCount = 1;
            }

            int completed = Math.min(7, Math.max(1, (interviewCount + appCount)));
            int streak = Math.max(1, completed);
            double hours = 3.5 + (completed * 2.5);
            
            List<Boolean> weekly = new ArrayList<>();
            for (int i = 0; i < 7; i++) {
                weekly.add(i < completed);
            }

            String suggestion = completed >= 7
                    ? "7-Day goal achieved! You're in the top 5% 🔥"
                    : "Practice today's challenge to reach " + (completed + 1) + "-day streak!";

            return new UserLearningGoal(targetEmail, 7, completed, weekly, Math.round(hours * 10.0) / 10.0, streak, today.toString(), suggestion);
        }
    }

    public UserLearningGoal completeToday(String email) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email.trim() : "";
        LocalDate today = LocalDate.now();
        if (targetEmail.isEmpty()) {
            return new UserLearningGoal("", 7, 1, List.of(true,false,false,false,false,false,false), 1.0, 1, today.toString(), "Great job starting your streak!");
        }
        UserLearningGoal current = getLearningGoal(targetEmail);
        
        int newStreak = current.getStreakCount();
        if (current.getLastActiveDate() != null && !current.getLastActiveDate().isEmpty()) {
            try {
                LocalDate lastDate = LocalDate.parse(current.getLastActiveDate().split("T")[0]);
                long daysDiff = ChronoUnit.DAYS.between(lastDate, today);
                if (daysDiff == 1) {
                    // Consecutive day -> streak increments!
                    newStreak = current.getStreakCount() + 1;
                } else if (daysDiff == 0) {
                    // Already active today
                    newStreak = Math.max(1, current.getStreakCount());
                } else {
                    // Missed days -> fresh start at 1
                    newStreak = 1;
                }
            } catch (Exception e) {
                newStreak = current.getStreakCount() + 1;
            }
        } else {
            newStreak = 1;
        }

        int newCompleted = Math.min(7, current.getCompletedDaysCount() + 1);
        double newHours = current.getTotalHoursLearned() + 1.5;
        
        List<Boolean> newWeekly = new ArrayList<>();
        int todayWeekdayIdx = today.getDayOfWeek().getValue() - 1; // 0=Mon, 6=Sun
        for (int i = 0; i < 7; i++) {
            boolean wasDone = i < current.getWeeklyDaysCompleted().size() && current.getWeeklyDaysCompleted().get(i);
            if (i == todayWeekdayIdx || wasDone) {
                newWeekly.add(true);
            } else {
                newWeekly.add(false);
            }
        }

        String newSuggestion = newCompleted >= 7
                ? "Weekly target crushed! Outstanding consistency 🏆"
                : "Keep up the momentum! " + (7 - newCompleted) + " days left to complete your weekly goal.";

        UserLearningGoal updated = new UserLearningGoal(
            targetEmail,
            7,
            newCompleted,
            newWeekly,
            Math.round(newHours * 10.0) / 10.0,
            newStreak,
            today.toString(),
            newSuggestion
        );

        // 1. Sync to public.user_learning_goals table
        try {
            String upsertSql = "INSERT INTO public.user_learning_goals (user_email, target_days, completed_days_count, total_hours_learned, streak_count, last_active_date, next_goal_suggestion) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?) " +
                    "ON CONFLICT (user_email) DO UPDATE SET " +
                    "completed_days_count = EXCLUDED.completed_days_count, " +
                    "total_hours_learned = EXCLUDED.total_hours_learned, " +
                    "streak_count = EXCLUDED.streak_count, " +
                    "last_active_date = EXCLUDED.last_active_date, " +
                    "next_goal_suggestion = EXCLUDED.next_goal_suggestion";
            jdbcTemplate.update(upsertSql, targetEmail, updated.getTargetDays(), updated.getCompletedDaysCount(), updated.getTotalHoursLearned(), updated.getStreakCount(), updated.getLastActiveDate(), updated.getNextGoalSuggestion());
        } catch (Exception ignored) {}

        // 2. Sync to public.users table as well
        try {
            String userUpdateSql = "UPDATE public.users SET current_streak = ?, last_active_date = ?, total_study_minutes = total_study_minutes + 90 WHERE email = ?";
            jdbcTemplate.update(userUpdateSql, newStreak, today.toString(), targetEmail);
        } catch (Exception ignored) {}

        return updated;
    }
}


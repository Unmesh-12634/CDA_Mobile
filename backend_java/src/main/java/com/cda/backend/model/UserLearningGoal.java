package com.cda.backend.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class UserLearningGoal {
    @JsonProperty("user_email")
    private String userEmail;
    
    @JsonProperty("target_days")
    private int targetDays;
    
    @JsonProperty("completed_days_count")
    private int completedDaysCount;
    
    @JsonProperty("weekly_days_completed")
    private List<Boolean> weeklyDaysCompleted; // 7 booleans: Mon -> Sun
    
    @JsonProperty("total_hours_learned")
    private double totalHoursLearned;
    
    @JsonProperty("streak_count")
    private int streakCount;
    
    @JsonProperty("last_active_date")
    private String lastActiveDate;
    
    @JsonProperty("next_goal_suggestion")
    private String nextGoalSuggestion;

    public UserLearningGoal() {
        this.targetDays = 5;
        this.completedDaysCount = 4;
        this.weeklyDaysCompleted = new ArrayList<>(Arrays.asList(true, true, true, true, false, false, false));
        this.totalHoursLearned = 14.5;
        this.streakCount = 4;
        this.nextGoalSuggestion = "Complete today's challenge to reach 5-day streak!";
    }

    public UserLearningGoal(String userEmail, int targetDays, int completedDaysCount, List<Boolean> weeklyDaysCompleted, double totalHoursLearned, int streakCount, String lastActiveDate, String nextGoalSuggestion) {
        this.userEmail = userEmail;
        this.targetDays = targetDays;
        this.completedDaysCount = completedDaysCount;
        this.weeklyDaysCompleted = weeklyDaysCompleted != null ? weeklyDaysCompleted : new ArrayList<>(Arrays.asList(false, false, false, false, false, false, false));
        this.totalHoursLearned = totalHoursLearned;
        this.streakCount = streakCount;
        this.lastActiveDate = lastActiveDate;
        this.nextGoalSuggestion = nextGoalSuggestion;
    }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public int getTargetDays() { return targetDays; }
    public void setTargetDays(int targetDays) { this.targetDays = targetDays; }

    public int getCompletedDaysCount() { return completedDaysCount; }
    public void setCompletedDaysCount(int completedDaysCount) { this.completedDaysCount = completedDaysCount; }

    public List<Boolean> getWeeklyDaysCompleted() { return weeklyDaysCompleted; }
    public void setWeeklyDaysCompleted(List<Boolean> weeklyDaysCompleted) { this.weeklyDaysCompleted = weeklyDaysCompleted; }

    public double getTotalHoursLearned() { return totalHoursLearned; }
    public void setTotalHoursLearned(double totalHoursLearned) { this.totalHoursLearned = totalHoursLearned; }

    public int getStreakCount() { return streakCount; }
    public void setStreakCount(int streakCount) { this.streakCount = streakCount; }

    public String getLastActiveDate() { return lastActiveDate; }
    public void setLastActiveDate(String lastActiveDate) { this.lastActiveDate = lastActiveDate; }

    public String getNextGoalSuggestion() { return nextGoalSuggestion; }
    public void setNextGoalSuggestion(String nextGoalSuggestion) { this.nextGoalSuggestion = nextGoalSuggestion; }
}

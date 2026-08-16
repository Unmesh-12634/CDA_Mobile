package com.cda.backend.model;

import java.util.List;

public class UserProgress {
    private int streakCount;
    private List<Boolean> weeklyDaysCompleted; // 7 days: Mon-Sun
    private int totalStudyMinutes;
    private String lastActiveDate;

    public UserProgress() {}

    public UserProgress(int streakCount, List<Boolean> weeklyDaysCompleted, int totalStudyMinutes, String lastActiveDate) {
        this.streakCount = streakCount;
        this.weeklyDaysCompleted = weeklyDaysCompleted;
        this.totalStudyMinutes = totalStudyMinutes;
        this.lastActiveDate = lastActiveDate;
    }

    public int getStreakCount() { return streakCount; }
    public void setStreakCount(int streakCount) { this.streakCount = streakCount; }

    public List<Boolean> getWeeklyDaysCompleted() { return weeklyDaysCompleted; }
    public void setWeeklyDaysCompleted(List<Boolean> weeklyDaysCompleted) { this.weeklyDaysCompleted = weeklyDaysCompleted; }

    public int getTotalStudyMinutes() { return totalStudyMinutes; }
    public void setTotalStudyMinutes(int totalStudyMinutes) { this.totalStudyMinutes = totalStudyMinutes; }

    public String getLastActiveDate() { return lastActiveDate; }
    public void setLastActiveDate(String lastActiveDate) { this.lastActiveDate = lastActiveDate; }
}

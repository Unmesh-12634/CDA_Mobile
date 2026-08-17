package com.cda.backend.model;

public class UserAnalytics {
    // Interview stats
    private int totalInterviews;
    private double avgInterviewScore;
    private double bestInterviewScore;
    private String lastInterviewDate;

    // Learning streak
    private int currentStreak;
    private int longestStreak;
    private int completedDaysCount;
    private double totalHoursLearned;

    // Job activity
    private int totalApplications;
    private int savedJobsCount;

    // Quiz stats
    private int totalQuizzes;
    private double avgQuizScore;
    private int bestQuizScore;

    // Profile
    private int profileStrengthScore;
    private String targetRole;

    public UserAnalytics() {}

    public int getTotalInterviews() { return totalInterviews; }
    public void setTotalInterviews(int totalInterviews) { this.totalInterviews = totalInterviews; }

    public double getAvgInterviewScore() { return avgInterviewScore; }
    public void setAvgInterviewScore(double avgInterviewScore) { this.avgInterviewScore = avgInterviewScore; }

    public double getBestInterviewScore() { return bestInterviewScore; }
    public void setBestInterviewScore(double bestInterviewScore) { this.bestInterviewScore = bestInterviewScore; }

    public String getLastInterviewDate() { return lastInterviewDate; }
    public void setLastInterviewDate(String lastInterviewDate) { this.lastInterviewDate = lastInterviewDate; }

    public int getCurrentStreak() { return currentStreak; }
    public void setCurrentStreak(int currentStreak) { this.currentStreak = currentStreak; }

    public int getLongestStreak() { return longestStreak; }
    public void setLongestStreak(int longestStreak) { this.longestStreak = longestStreak; }

    public int getCompletedDaysCount() { return completedDaysCount; }
    public void setCompletedDaysCount(int completedDaysCount) { this.completedDaysCount = completedDaysCount; }

    public double getTotalHoursLearned() { return totalHoursLearned; }
    public void setTotalHoursLearned(double totalHoursLearned) { this.totalHoursLearned = totalHoursLearned; }

    public int getTotalApplications() { return totalApplications; }
    public void setTotalApplications(int totalApplications) { this.totalApplications = totalApplications; }

    public int getSavedJobsCount() { return savedJobsCount; }
    public void setSavedJobsCount(int savedJobsCount) { this.savedJobsCount = savedJobsCount; }

    public int getTotalQuizzes() { return totalQuizzes; }
    public void setTotalQuizzes(int totalQuizzes) { this.totalQuizzes = totalQuizzes; }

    public double getAvgQuizScore() { return avgQuizScore; }
    public void setAvgQuizScore(double avgQuizScore) { this.avgQuizScore = avgQuizScore; }

    public int getBestQuizScore() { return bestQuizScore; }
    public void setBestQuizScore(int bestQuizScore) { this.bestQuizScore = bestQuizScore; }

    public int getProfileStrengthScore() { return profileStrengthScore; }
    public void setProfileStrengthScore(int profileStrengthScore) { this.profileStrengthScore = profileStrengthScore; }

    public String getTargetRole() { return targetRole; }
    public void setTargetRole(String targetRole) { this.targetRole = targetRole; }
}

package com.cda.backend.model;

public class QuizResult {
    private String id;
    private String userEmail;
    private int score;
    private int correctCount;
    private int totalQuestions;
    private String category;
    private String skillFocus;
    private String completedAt;

    public QuizResult() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public int getScore() { return score; }
    public void setScore(int score) { this.score = score; }

    public int getCorrectCount() { return correctCount; }
    public void setCorrectCount(int correctCount) { this.correctCount = correctCount; }

    public int getTotalQuestions() { return totalQuestions; }
    public void setTotalQuestions(int totalQuestions) { this.totalQuestions = totalQuestions; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getSkillFocus() { return skillFocus; }
    public void setSkillFocus(String skillFocus) { this.skillFocus = skillFocus; }

    public String getCompletedAt() { return completedAt; }
    public void setCompletedAt(String completedAt) { this.completedAt = completedAt; }
}

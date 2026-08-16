package com.cda.backend.model;

import java.util.List;
import java.util.Map;

public class InterviewReport {
    private String id;
    private String userId;
    private String targetRole;
    private double overallScore;
    private String feedbackSummary;
    private List<String> strengths;
    private List<String> improvements;
    private Map<String, Object> detailedQaJson;
    private int durationSeconds;
    private String createdAt;

    public InterviewReport() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getTargetRole() { return targetRole; }
    public void setTargetRole(String targetRole) { this.targetRole = targetRole; }

    public double getOverallScore() { return overallScore; }
    public void setOverallScore(double overallScore) { this.overallScore = overallScore; }

    public String getFeedbackSummary() { return feedbackSummary; }
    public void setFeedbackSummary(String feedbackSummary) { this.feedbackSummary = feedbackSummary; }

    public List<String> getStrengths() { return strengths; }
    public void setStrengths(List<String> strengths) { this.strengths = strengths; }

    public List<String> getImprovements() { return improvements; }
    public void setImprovements(List<String> improvements) { this.improvements = improvements; }

    public Map<String, Object> getDetailedQaJson() { return detailedQaJson; }
    public void setDetailedQaJson(Map<String, Object> detailedQaJson) { this.detailedQaJson = detailedQaJson; }

    public int getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(int durationSeconds) { this.durationSeconds = durationSeconds; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}

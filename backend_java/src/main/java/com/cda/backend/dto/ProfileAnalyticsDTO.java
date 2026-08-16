package com.cda.backend.dto;

import java.util.List;
import java.util.Map;

public class ProfileAnalyticsDTO {
    private int profileStrengthPercentage;
    private String strengthHint;
    private List<String> missingFields;
    private Map<String, Double> top5DomainAffinities;
    private int completedMockInterviews;
    private int savedJobsCount;
    private int savedReelsCount;

    public ProfileAnalyticsDTO() {}

    public int getProfileStrengthPercentage() { return profileStrengthPercentage; }
    public void setProfileStrengthPercentage(int profileStrengthPercentage) { this.profileStrengthPercentage = profileStrengthPercentage; }

    public String getStrengthHint() { return strengthHint; }
    public void setStrengthHint(String strengthHint) { this.strengthHint = strengthHint; }

    public List<String> getMissingFields() { return missingFields; }
    public void setMissingFields(List<String> missingFields) { this.missingFields = missingFields; }

    public Map<String, Double> getTop5DomainAffinities() { return top5DomainAffinities; }
    public void setTop5DomainAffinities(Map<String, Double> top5DomainAffinities) { this.top5DomainAffinities = top5DomainAffinities; }

    public int getCompletedMockInterviews() { return completedMockInterviews; }
    public void setCompletedMockInterviews(int completedMockInterviews) { this.completedMockInterviews = completedMockInterviews; }

    public int getSavedJobsCount() { return savedJobsCount; }
    public void setSavedJobsCount(int savedJobsCount) { this.savedJobsCount = savedJobsCount; }

    public int getSavedReelsCount() { return savedReelsCount; }
    public void setSavedReelsCount(int savedReelsCount) { this.savedReelsCount = savedReelsCount; }
}

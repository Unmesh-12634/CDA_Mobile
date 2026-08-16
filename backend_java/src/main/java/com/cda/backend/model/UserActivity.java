package com.cda.backend.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;

public class UserActivity {
    private String id;
    
    @JsonProperty("user_email")
    private String userEmail;
    
    @JsonProperty("activity_type")
    private String activityType; // JOB_APPLIED, INTERVIEW_COMPLETED, REEL_SAVED, QUIZ_COMPLETED, PROFILE_UPDATED
    
    private String title;
    private String subtitle;
    private String route;
    
    @JsonProperty("icon_type")
    private String iconType; // work, interview, play, quiz, profile
    
    @JsonProperty("created_at")
    private LocalDateTime createdAt;

    public UserActivity() {
        this.createdAt = LocalDateTime.now();
    }

    public UserActivity(String id, String userEmail, String activityType, String title, String subtitle, String route, String iconType, LocalDateTime createdAt) {
        this.id = id;
        this.userEmail = userEmail;
        this.activityType = activityType;
        this.title = title;
        this.subtitle = subtitle;
        this.route = route;
        this.iconType = iconType;
        this.createdAt = createdAt != null ? createdAt : LocalDateTime.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public String getActivityType() { return activityType; }
    public void setActivityType(String activityType) { this.activityType = activityType; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getSubtitle() { return subtitle; }
    public void setSubtitle(String subtitle) { this.subtitle = subtitle; }

    public String getRoute() { return route; }
    public void setRoute(String route) { this.route = route; }

    public String getIconType() { return iconType; }
    public void setIconType(String iconType) { this.iconType = iconType; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}

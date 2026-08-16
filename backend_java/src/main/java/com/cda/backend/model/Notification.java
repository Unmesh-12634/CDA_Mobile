package com.cda.backend.model;

public class Notification {
    private String id;
    private String userEmail;
    private String title;
    private String message;
    private String type; // INTERVIEW, JOB, PROFILE, SYSTEM
    private String actionUrl;
    private boolean isRead;
    private String createdAt;

    public Notification() {}

    public Notification(String id, String userEmail, String title, String message, String type, String actionUrl, boolean isRead, String createdAt) {
        this.id = id;
        this.userEmail = userEmail;
        this.title = title;
        this.message = message;
        this.type = type;
        this.actionUrl = actionUrl;
        this.isRead = isRead;
        this.createdAt = createdAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getActionUrl() { return actionUrl; }
    public void setActionUrl(String actionUrl) { this.actionUrl = actionUrl; }

    public boolean isRead() { return isRead; }
    public void setRead(boolean read) { isRead = read; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}

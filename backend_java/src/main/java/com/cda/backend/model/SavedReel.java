package com.cda.backend.model;

public class SavedReel {
    private String id;
    private String userId;
    private String reelId;
    private String createdAt;

    public SavedReel() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getReelId() { return reelId; }
    public void setReelId(String reelId) { this.reelId = reelId; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}

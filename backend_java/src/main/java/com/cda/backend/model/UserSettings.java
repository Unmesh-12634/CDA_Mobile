package com.cda.backend.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;

public class UserSettings {
    @JsonProperty("user_email")
    private String userEmail;

    @JsonProperty("ai_voice_persona")
    private String aiVoicePersona;

    @JsonProperty("realtime_audio")
    private boolean realtimeAudio;

    @JsonProperty("auto_record")
    private boolean autoRecord;

    @JsonProperty("email_notifications")
    private boolean emailNotifications;

    @JsonProperty("push_notifications")
    private boolean pushNotifications;

    @JsonProperty("haptic_feedback")
    private boolean hapticFeedback;

    @JsonProperty("theme_mode")
    private String themeMode; // "system", "dark", "light"

    @JsonProperty("two_factor_enabled")
    private boolean twoFactorEnabled;

    @JsonProperty("storage_cache_mb")
    private double storageCacheMb;

    @JsonProperty("updated_at")
    private String updatedAt;

    public UserSettings() {}

    public UserSettings(String userEmail, String aiVoicePersona, boolean realtimeAudio, boolean autoRecord,
                        boolean emailNotifications, boolean pushNotifications, boolean hapticFeedback,
                        String themeMode, boolean twoFactorEnabled, double storageCacheMb, String updatedAt) {
        this.userEmail = userEmail;
        this.aiVoicePersona = aiVoicePersona;
        this.realtimeAudio = realtimeAudio;
        this.autoRecord = autoRecord;
        this.emailNotifications = emailNotifications;
        this.pushNotifications = pushNotifications;
        this.hapticFeedback = hapticFeedback;
        this.themeMode = themeMode;
        this.twoFactorEnabled = twoFactorEnabled;
        this.storageCacheMb = storageCacheMb;
        this.updatedAt = updatedAt;
    }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public String getAiVoicePersona() { return aiVoicePersona; }
    public void setAiVoicePersona(String aiVoicePersona) { this.aiVoicePersona = aiVoicePersona; }

    public boolean isRealtimeAudio() { return realtimeAudio; }
    public void setRealtimeAudio(boolean realtimeAudio) { this.realtimeAudio = realtimeAudio; }

    public boolean isAutoRecord() { return autoRecord; }
    public void setAutoRecord(boolean autoRecord) { this.autoRecord = autoRecord; }

    public boolean isEmailNotifications() { return emailNotifications; }
    public void setEmailNotifications(boolean emailNotifications) { this.emailNotifications = emailNotifications; }

    public boolean isPushNotifications() { return pushNotifications; }
    public void setPushNotifications(boolean pushNotifications) { this.pushNotifications = pushNotifications; }

    public boolean isHapticFeedback() { return hapticFeedback; }
    public void setHapticFeedback(boolean hapticFeedback) { this.hapticFeedback = hapticFeedback; }

    public String getThemeMode() { return themeMode; }
    public void setThemeMode(String themeMode) { this.themeMode = themeMode; }

    public boolean isTwoFactorEnabled() { return twoFactorEnabled; }
    public void setTwoFactorEnabled(boolean twoFactorEnabled) { this.twoFactorEnabled = twoFactorEnabled; }

    public double getStorageCacheMb() { return storageCacheMb; }
    public void setStorageCacheMb(double storageCacheMb) { this.storageCacheMb = storageCacheMb; }

    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }
}

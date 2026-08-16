package com.cda.backend.dao;

import com.cda.backend.model.UserSettings;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public class UserSettingsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public UserSettings getUserSettings(String email) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email : "unii12634@gmail.com";
        try {
            String sql = "SELECT user_email, ai_voice_persona, realtime_audio, auto_record, email_notifications, push_notifications, haptic_feedback, theme_mode, two_factor_enabled, updated_at FROM public.user_settings WHERE user_email = ? LIMIT 1";
            return jdbcTemplate.queryForObject(sql, (rs, rowNum) -> new UserSettings(
                rs.getString("user_email"),
                rs.getString("ai_voice_persona"),
                rs.getBoolean("realtime_audio"),
                rs.getBoolean("auto_record"),
                rs.getBoolean("email_notifications"),
                rs.getBoolean("push_notifications"),
                rs.getBoolean("haptic_feedback"),
                rs.getString("theme_mode"),
                rs.getBoolean("two_factor_enabled"),
                14.2,
                rs.getString("updated_at")
            ), targetEmail);
        } catch (Exception e) {
            // Default fallback settings
            return new UserSettings(
                targetEmail,
                "Samantha (Natural AI)",
                true,
                true,
                true,
                true,
                true,
                "system",
                false,
                14.2,
                LocalDateTime.now().toString()
            );
        }
    }

    public UserSettings saveUserSettings(UserSettings settings) {
        String targetEmail = (settings.getUserEmail() != null && !settings.getUserEmail().trim().isEmpty())
                ? settings.getUserEmail()
                : "unii12634@gmail.com";

        String now = LocalDateTime.now().toString();
        settings.setUserEmail(targetEmail);
        settings.setUpdatedAt(now);

        try {
            String createTableSql = "CREATE TABLE IF NOT EXISTS public.user_settings (" +
                    "user_email VARCHAR(255) PRIMARY KEY, " +
                    "ai_voice_persona VARCHAR(100) DEFAULT 'Samantha (Natural AI)', " +
                    "realtime_audio BOOLEAN DEFAULT TRUE, " +
                    "auto_record BOOLEAN DEFAULT TRUE, " +
                    "email_notifications BOOLEAN DEFAULT TRUE, " +
                    "push_notifications BOOLEAN DEFAULT TRUE, " +
                    "haptic_feedback BOOLEAN DEFAULT TRUE, " +
                    "theme_mode VARCHAR(50) DEFAULT 'system', " +
                    "two_factor_enabled BOOLEAN DEFAULT FALSE, " +
                    "updated_at VARCHAR(100)" +
                    ");";
            jdbcTemplate.execute(createTableSql);

            String upsertSql = "INSERT INTO public.user_settings (user_email, ai_voice_persona, realtime_audio, auto_record, email_notifications, push_notifications, haptic_feedback, theme_mode, two_factor_enabled, updated_at) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) " +
                    "ON CONFLICT (user_email) DO UPDATE SET " +
                    "ai_voice_persona = EXCLUDED.ai_voice_persona, " +
                    "realtime_audio = EXCLUDED.realtime_audio, " +
                    "auto_record = EXCLUDED.auto_record, " +
                    "email_notifications = EXCLUDED.email_notifications, " +
                    "push_notifications = EXCLUDED.push_notifications, " +
                    "haptic_feedback = EXCLUDED.haptic_feedback, " +
                    "theme_mode = EXCLUDED.theme_mode, " +
                    "two_factor_enabled = EXCLUDED.two_factor_enabled, " +
                    "updated_at = EXCLUDED.updated_at;";

            jdbcTemplate.update(upsertSql,
                targetEmail,
                settings.getAiVoicePersona(),
                settings.isRealtimeAudio(),
                settings.isAutoRecord(),
                settings.isEmailNotifications(),
                settings.isPushNotifications(),
                settings.isHapticFeedback(),
                settings.getThemeMode(),
                settings.isTwoFactorEnabled(),
                now
            );
        } catch (Exception e) {
            // Fallback gracefully
        }
        return settings;
    }
}

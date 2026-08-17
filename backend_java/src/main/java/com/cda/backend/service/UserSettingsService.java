package com.cda.backend.service;

import com.cda.backend.dao.UserSettingsDAO;
import com.cda.backend.model.UserSettings;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class UserSettingsService {

    @Autowired
    private UserSettingsDAO userSettingsDAO;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public UserSettings getUserSettings(String email) {
        return userSettingsDAO.getUserSettings(email);
    }

    public UserSettings saveUserSettings(UserSettings settings) {
        return userSettingsDAO.saveUserSettings(settings);
    }

    public Map<String, Object> exportUserData(String email) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email.trim() : "";
        Map<String, Object> export = new HashMap<>();
        export.put("export_timestamp", java.time.LocalDateTime.now().toString());
        export.put("user_email", targetEmail);

        // 1. Settings
        export.put("settings", userSettingsDAO.getUserSettings(targetEmail));

        // 2. Applications
        try {
            List<Map<String, Object>> apps = jdbcTemplate.queryForList(
                "SELECT * FROM public.job_applications WHERE user_email = ? ORDER BY applied_at DESC",
                targetEmail
            );
            export.put("job_applications", apps);
        } catch (Exception e) {
            export.put("job_applications", List.of());
        }

        // 3. Interview Reports
        try {
            List<Map<String, Object>> interviews = jdbcTemplate.queryForList(
                "SELECT * FROM public.ai_interview_reports WHERE candidate_email = ? ORDER BY created_at DESC",
                targetEmail
            );
            export.put("interview_reports", interviews);
        } catch (Exception e) {
            export.put("interview_reports", List.of());
        }

        // 4. Saved Items
        try {
            List<Map<String, Object>> savedJobs = jdbcTemplate.queryForList(
                "SELECT * FROM public.saved_jobs WHERE user_email = ?",
                targetEmail
            );
            export.put("saved_jobs", savedJobs);
        } catch (Exception e) {
            export.put("saved_jobs", List.of());
        }

        return export;
    }
}

package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.UserLearningGoal;
import com.cda.backend.service.UserLearningGoalService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/user/goals")
@CrossOrigin(origins = "*")
public class UserLearningGoalController {

    @Autowired
    private UserLearningGoalService userLearningGoalService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping
    public ResponseEntity<UserLearningGoal> getGoals(@RequestParam(name = "email", required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(new UserLearningGoal());
        }
        UserLearningGoal goal = userLearningGoalService.getLearningGoal(email.trim());
        return ResponseEntity.ok(goal);
    }

    @PostMapping("/complete-today")
    public ResponseEntity<UserLearningGoal> completeToday(@RequestParam(name = "email", required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(new UserLearningGoal());
        }
        UserLearningGoal updated = userLearningGoalService.completeToday(email.trim());
        return ResponseEntity.ok(updated);
    }

    /**
     * Roadmap data: combines target_role from users table + learning goal metrics.
     * Used by Flutter CareerRoadmapScreen to show real progress and auto-select path.
     */
    @GetMapping("/roadmap")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getRoadmapData(
            @RequestParam(name = "email", required = false, defaultValue = "") String email) {
        Map<String, Object> data = new HashMap<>();

        // Get target role from users table
        try {
            Map<String, Object> userRow = jdbcTemplate.queryForMap(
                "SELECT COALESCE(target_role, 'Full-Stack Java Engineer') as target_role FROM public.users WHERE email = ?",
                email.trim());
            data.put("targetRole", userRow.get("target_role"));
        } catch (Exception e) {
            data.put("targetRole", "Full-Stack Java Engineer");
        }

        // Get learning goal metrics
        try {
            UserLearningGoal goal = userLearningGoalService.getLearningGoal(email);
            data.put("completedDaysCount", goal.getCompletedDaysCount());
            data.put("streakCount", goal.getStreakCount());
            data.put("totalHoursLearned", goal.getTotalHoursLearned());
            data.put("nextGoalSuggestion", goal.getNextGoalSuggestion());
        } catch (Exception e) {
            data.put("completedDaysCount", 0);
            data.put("streakCount", 0);
            data.put("totalHoursLearned", 0.0);
            data.put("nextGoalSuggestion", "Complete your first interview to unlock insights!");
        }

        // Compute interview count as progress proxy for phases
        try {
            Integer interviewCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM public.ai_interview_reports WHERE candidate_email = ?",
                Integer.class, email);
            data.put("interviewCount", interviewCount != null ? interviewCount : 0);
        } catch (Exception e) {
            data.put("interviewCount", 0);
        }

        return ResponseEntity.ok(ApiResponse.ok(data, "Roadmap data fetched successfully"));
    }
}


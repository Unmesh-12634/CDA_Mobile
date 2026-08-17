package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.QuizResult;
import com.cda.backend.service.QuizService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/quiz")
@CrossOrigin(origins = "*")
public class QuizController {

    @Autowired
    private QuizService quizService;

    @PostMapping("/save-result")
    public ResponseEntity<ApiResponse<Boolean>> saveResult(@RequestBody Map<String, Object> body) {
        String email = (String) body.getOrDefault("email", "");
        if (email.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Email required"));
        }
        int score = body.get("score") != null ? ((Number) body.get("score")).intValue() : 0;
        int correctCount = body.get("correctCount") != null ? ((Number) body.get("correctCount")).intValue() : 0;
        int totalQuestions = body.get("totalQuestions") != null ? ((Number) body.get("totalQuestions")).intValue() : 5;
        String category = (String) body.getOrDefault("category", "Mixed");
        String skillFocus = (String) body.getOrDefault("skillFocus", "General");

        boolean saved = quizService.saveResult(email, score, correctCount, totalQuestions, category, skillFocus);
        return ResponseEntity.ok(ApiResponse.ok(saved, saved ? "Quiz result saved" : "Failed to save quiz result"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<QuizResult>>> getHistory(
            @RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.ok(List.of(), "Quiz history retrieved"));
        }
        List<QuizResult> history = quizService.getHistory(email);
        return ResponseEntity.ok(ApiResponse.ok(history, "Quiz history retrieved"));
    }

    @GetMapping("/today-attempts")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getTodayAttempts(
            @RequestParam(required = false, defaultValue = "") String email) {
        int todayCount = email.trim().isEmpty() ? 0 : quizService.getTodayCount(email);
        int maxDaily = 5;
        Map<String, Object> resp = Map.of(
            "email", email,
            "todayCompleted", todayCount,
            "maxDailyLimit", maxDaily,
            "remainingToday", Math.max(0, maxDaily - todayCount),
            "canTakeQuiz", todayCount < maxDaily
        );
        return ResponseEntity.ok(ApiResponse.ok(resp, "Today quiz attempts retrieved"));
    }
}


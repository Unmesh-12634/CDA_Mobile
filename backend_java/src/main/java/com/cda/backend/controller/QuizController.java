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
        String email = (String) body.getOrDefault("email", "unii12634@gmail.com");
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
            @RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        List<QuizResult> history = quizService.getHistory(email);
        return ResponseEntity.ok(ApiResponse.ok(history, "Quiz history retrieved"));
    }
}

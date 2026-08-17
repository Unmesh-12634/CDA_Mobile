package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.InterviewReport;
import com.cda.backend.service.InterviewReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/interview/reports")
@CrossOrigin(origins = "*")
public class InterviewReportController {

    @Autowired
    private InterviewReportService interviewReportService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<InterviewReport>>> getReports(
            @RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.ok(List.of(), "Interview reports fetched"));
        }
        List<InterviewReport> reports = interviewReportService.getReports(email.trim());
        return ResponseEntity.ok(ApiResponse.ok(reports, "Interview reports fetched"));
    }

    @PostMapping("/save")
    public ResponseEntity<ApiResponse<Boolean>> saveReport(@RequestBody Map<String, Object> payload) {
        String email = (String) payload.getOrDefault("email", "");
        if (email.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("User email is required"));
        }
        String role = (String) payload.getOrDefault("targetRole", "Software Developer");
        double score = ((Number) payload.getOrDefault("overallScore", 85.0)).doubleValue();
        String summary = (String) payload.getOrDefault("feedbackSummary", "Completed session");
        int duration = ((Number) payload.getOrDefault("durationSeconds", 300)).intValue();
        String qaJson = (String) payload.getOrDefault("detailedQaJson", "{}");

        boolean saved = interviewReportService.saveReport(email, role, score, summary, null, null, qaJson, duration);
        return ResponseEntity.ok(ApiResponse.ok(saved, "Report saved successfully"));
    }
}

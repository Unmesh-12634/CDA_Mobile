package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.UserAnalytics;
import com.cda.backend.service.AnalyticsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/analytics")
@CrossOrigin(origins = "*")
public class AnalyticsController {

    @Autowired
    private AnalyticsService analyticsService;

    @GetMapping
    public ResponseEntity<ApiResponse<UserAnalytics>> getAnalytics(
            @RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.ok(new UserAnalytics(), "Analytics initialized"));
        }
        UserAnalytics analytics = analyticsService.getAnalytics(email);
        return ResponseEntity.ok(ApiResponse.ok(analytics, "Analytics fetched successfully"));
    }
}

package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.UserProgress;
import com.cda.backend.service.ProgressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/progress")
@CrossOrigin(origins = "*")
public class ProgressController {

    @Autowired
    private ProgressService progressService;

    @GetMapping
    public ResponseEntity<ApiResponse<UserProgress>> getProgress(@RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.success(new UserProgress()));
        }
        UserProgress progress = progressService.getProgress(email.trim());
        return ResponseEntity.ok(ApiResponse.success(progress));
    }

    @PostMapping("/complete-today")
    public ResponseEntity<ApiResponse<Boolean>> completeToday(@RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.success("Today marked as completed", true));
        }
        boolean ok = progressService.completeToday(email.trim());
        return ResponseEntity.ok(ApiResponse.success("Today marked as completed", ok));
    }
}

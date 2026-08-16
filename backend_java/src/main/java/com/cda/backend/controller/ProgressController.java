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
    public ResponseEntity<ApiResponse<UserProgress>> getProgress(@RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        UserProgress progress = progressService.getProgress(email);
        return ResponseEntity.ok(ApiResponse.success(progress));
    }

    @PostMapping("/complete-today")
    public ResponseEntity<ApiResponse<Boolean>> completeToday(@RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        boolean ok = progressService.completeToday(email);
        return ResponseEntity.ok(ApiResponse.success("Today marked as completed", ok));
    }
}

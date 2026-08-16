package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.dto.ApplicationRequest;
import com.cda.backend.dto.StatusUpdateRequest;
import com.cda.backend.model.JobApplication;
import com.cda.backend.service.JobApplicationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/applications")
public class ApplicationsController {

    @Autowired
    private JobApplicationService applicationService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<JobApplication>>> getApplications(
            @RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        List<JobApplication> apps = applicationService.getUserApplications(email);
        return ResponseEntity.ok(ApiResponse.ok(apps, "Applications fetched successfully"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Boolean>> apply(@RequestBody ApplicationRequest request) {
        boolean success = applicationService.apply(
                request.getJobId(),
                request.getEmail(),
                request.getResumeUrl()
        );
        return ResponseEntity.ok(ApiResponse.ok(success, "Application submitted successfully"));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<Boolean>> updateStatus(
            @PathVariable String id,
            @RequestBody StatusUpdateRequest request) {
        boolean success = applicationService.updateStatus(id, request.getStatus());
        return ResponseEntity.ok(ApiResponse.ok(success, "Application status updated successfully"));
    }
}

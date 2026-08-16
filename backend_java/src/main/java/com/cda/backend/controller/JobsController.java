package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.Job;
import com.cda.backend.service.JobService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/jobs")
@CrossOrigin(origins = "*")
public class JobsController {

    @Autowired
    private JobService jobService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Job>>> getAllJobs(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String query) {
        List<Job> jobs = jobService.getJobs(category, query);
        return ResponseEntity.ok(ApiResponse.ok(jobs, "Jobs fetched successfully"));
    }

    @GetMapping("/skills")
    public ResponseEntity<ApiResponse<List<String>>> getTrendingSkills() {
        List<String> skills = jobService.getTrendingSkills();
        return ResponseEntity.ok(ApiResponse.ok(skills, "Trending skills retrieved"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Job>> getJobById(@PathVariable String id) {
        Job job = jobService.getJobById(id);
        return ResponseEntity.ok(ApiResponse.ok(job, "Job details retrieved"));
    }
}

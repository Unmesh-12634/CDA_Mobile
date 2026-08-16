package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.dto.BookmarkRequest;
import com.cda.backend.service.BookmarkService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/saved-jobs")
public class SavedJobsController {

    @Autowired
    private BookmarkService bookmarkService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<String>>> getSavedJobIds() {
        List<String> ids = bookmarkService.getSavedJobIds();
        return ResponseEntity.ok(ApiResponse.ok(ids, "Saved job IDs retrieved"));
    }

    @PostMapping("/toggle")
    public ResponseEntity<ApiResponse<Boolean>> toggleSave(@RequestBody BookmarkRequest request) {
        boolean isSavedNow = bookmarkService.toggleSaveJob(request.getId());
        String msg = isSavedNow ? "Job bookmarked" : "Job removed from bookmarks";
        return ResponseEntity.ok(ApiResponse.ok(isSavedNow, msg));
    }
}

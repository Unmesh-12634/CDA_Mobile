package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.dto.BookmarkRequest;
import com.cda.backend.service.BookmarkService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/saved-reels")
public class SavedReelsController {

    @Autowired
    private BookmarkService bookmarkService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<String>>> getSavedReelIds() {
        List<String> ids = bookmarkService.getSavedReelIds();
        return ResponseEntity.ok(ApiResponse.ok(ids, "Saved reel IDs retrieved"));
    }

    @PostMapping("/toggle")
    public ResponseEntity<ApiResponse<Boolean>> toggleSave(@RequestBody BookmarkRequest request) {
        boolean isSavedNow = bookmarkService.toggleSaveReel(request.getId());
        String msg = isSavedNow ? "Reel bookmarked" : "Reel removed from bookmarks";
        return ResponseEntity.ok(ApiResponse.ok(isSavedNow, msg));
    }
}

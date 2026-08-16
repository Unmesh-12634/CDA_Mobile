package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.Reel;
import com.cda.backend.service.ReelService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/reels")
@CrossOrigin(origins = "*")
public class ReelsController {

    @Autowired
    private ReelService reelService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Reel>>> getTopReels(
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(required = false) String skill) {
        List<Reel> reels = reelService.getTopReels(limit, skill);
        return ResponseEntity.ok(ApiResponse.ok(reels, "Top reels retrieved"));
    }

    @PostMapping("/{id}/like")
    public ResponseEntity<ApiResponse<Boolean>> toggleLike(
            @PathVariable("id") String id,
            @RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        boolean liked = reelService.toggleLike(id, email);
        return ResponseEntity.ok(ApiResponse.ok(liked, liked ? "Liked reel" : "Unliked reel"));
    }

    @GetMapping("/{id}/comments")
    public ResponseEntity<ApiResponse<List<java.util.Map<String, Object>>>> getComments(
            @PathVariable("id") String id) {
        List<java.util.Map<String, Object>> comments = reelService.getComments(id);
        return ResponseEntity.ok(ApiResponse.ok(comments, "Reel comments retrieved"));
    }

    @PostMapping("/{id}/comments")
    public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> addComment(
            @PathVariable("id") String id,
            @RequestBody java.util.Map<String, String> body) {
        String email = body.getOrDefault("userEmail", "unii12634@gmail.com");
        String name = body.getOrDefault("userName", "Learner");
        String avatar = body.get("userAvatar");
        String comment = body.getOrDefault("comment", "");
        java.util.Map<String, Object> created = reelService.addComment(id, email, name, avatar, comment);
        return ResponseEntity.ok(ApiResponse.ok(created, "Comment added successfully"));
    }
}

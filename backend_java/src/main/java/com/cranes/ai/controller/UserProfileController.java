package com.cranes.ai.controller;

import com.cranes.ai.model.UserProfileDto;
import com.cranes.ai.service.UserProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/user")
@CrossOrigin(origins = "*")
public class UserProfileController {

    private final UserProfileService profileService;

    public UserProfileController(UserProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(@RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        return profileService.getProfileByEmail(email)
                .map(ResponseEntity::ok)
                .orElseGet(() -> {
                    Map<String, String> err = new HashMap<>();
                    err.put("error", "Profile not found for " + email);
                    return ResponseEntity.status(404).body((UserProfileDto) null);
                });
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(
            @RequestParam(defaultValue = "unii12634@gmail.com") String email,
            @RequestBody UserProfileDto profileDto) {
        boolean updated = profileService.updateProfile(email, profileDto);
        Map<String, Object> resp = new HashMap<>();
        if (updated) {
            resp.put("status", "success");
            resp.put("message", "Profile updated successfully via Java Spring Boot Backend!");
            resp.put("email", email);
            return ResponseEntity.ok(resp);
        } else {
            resp.put("status", "error");
            resp.put("message", "Failed to update profile in database");
            return ResponseEntity.status(500).body(resp);
        }
    }
}

package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.dto.ProfileAnalyticsDTO;
import com.cda.backend.model.UserProfile;
import com.cda.backend.service.UserProfileService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/profile")
public class UserProfileController {

    @Autowired
    private UserProfileService userProfileService;

    @GetMapping
    public ResponseEntity<ApiResponse<UserProfile>> getProfile(
            @RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        UserProfile profile = userProfileService.getProfileByEmail(email);
        return ResponseEntity.ok(ApiResponse.ok(profile, "Profile retrieved successfully"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserProfile>> saveProfile(@RequestBody UserProfile profile) {
        UserProfile saved = userProfileService.saveOrUpdateProfile(profile);
        return ResponseEntity.ok(ApiResponse.ok(saved, "Profile updated successfully via Java Backend"));
    }

    @GetMapping("/analytics")
    public ResponseEntity<ApiResponse<ProfileAnalyticsDTO>> getProfileAnalytics(
            @RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        ProfileAnalyticsDTO analytics = userProfileService.getProfileAnalytics(email);
        return ResponseEntity.ok(ApiResponse.ok(analytics, "Profile analytics calculated by Java Business Engine"));
    }
}

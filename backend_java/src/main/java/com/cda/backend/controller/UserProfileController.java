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
            @RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.ok(new UserProfile(), "Profile retrieved successfully"));
        }
        UserProfile profile = userProfileService.getProfileByEmail(email.trim());
        return ResponseEntity.ok(ApiResponse.ok(profile, "Profile retrieved successfully"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserProfile>> saveProfile(@RequestBody UserProfile profile) {
        UserProfile saved = userProfileService.saveOrUpdateProfile(profile);
        return ResponseEntity.ok(ApiResponse.ok(saved, "Profile updated successfully via Java Backend"));
    }

    @GetMapping("/analytics")
    public ResponseEntity<ApiResponse<ProfileAnalyticsDTO>> getProfileAnalytics(
            @RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.ok(new ProfileAnalyticsDTO(), "Empty analytics"));
        }
        ProfileAnalyticsDTO analytics = userProfileService.getProfileAnalytics(email.trim());
        return ResponseEntity.ok(ApiResponse.ok(analytics, "Profile analytics calculated by Java Business Engine"));
    }
}

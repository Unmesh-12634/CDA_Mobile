package com.cda.backend.controller;

import com.cda.backend.model.UserSettings;
import com.cda.backend.service.UserSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/user/settings")
@CrossOrigin(origins = "*")
public class UserSettingsController {

    @Autowired
    private UserSettingsService userSettingsService;

    @GetMapping
    public ResponseEntity<UserSettings> getUserSettings(@RequestParam(value = "email", required = false) String email) {
        return ResponseEntity.ok(userSettingsService.getUserSettings(email));
    }

    @PostMapping
    public ResponseEntity<UserSettings> saveUserSettings(@RequestBody UserSettings settings) {
        return ResponseEntity.ok(userSettingsService.saveUserSettings(settings));
    }

    @PutMapping
    public ResponseEntity<UserSettings> updateUserSettings(@RequestBody UserSettings settings) {
        return ResponseEntity.ok(userSettingsService.saveUserSettings(settings));
    }

    @PostMapping("/export-data")
    public ResponseEntity<Map<String, Object>> exportUserData(@RequestParam(value = "email", required = false) String email) {
        return ResponseEntity.ok(userSettingsService.exportUserData(email));
    }
}

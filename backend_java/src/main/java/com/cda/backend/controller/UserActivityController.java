package com.cda.backend.controller;

import com.cda.backend.model.UserActivity;
import com.cda.backend.service.UserActivityService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/user/activities")
@CrossOrigin(origins = "*")
public class UserActivityController {

    @Autowired
    private UserActivityService userActivityService;

    @GetMapping
    public ResponseEntity<List<UserActivity>> getUserActivities(@RequestParam(name = "email", required = false) String email) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email : "unii12634@gmail.com";
        List<UserActivity> list = userActivityService.getUserActivities(targetEmail);
        return ResponseEntity.ok(list);
    }
}

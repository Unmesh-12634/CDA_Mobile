package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.Notification;
import com.cda.backend.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/notifications")
@CrossOrigin(origins = "*")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Notification>>> getUserNotifications(
            @RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.success(List.of(), "No active session"));
        }
        List<Notification> list = notificationService.getUserNotifications(email.trim());
        return ResponseEntity.ok(ApiResponse.success(list, "Fetched " + list.size() + " notifications"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Boolean>> createNotification(@RequestBody Map<String, String> payload) {
        String email = payload.getOrDefault("email", "");
        if (email.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Email required"));
        }
        String title = payload.getOrDefault("title", "CDA Notification");
        String message = payload.getOrDefault("message", "");
        String type = payload.getOrDefault("type", "SYSTEM");
        String actionUrl = payload.getOrDefault("actionUrl", "");

        boolean ok = notificationService.createNotification(email, title, message, type, actionUrl);
        return ResponseEntity.ok(ApiResponse.success(ok, ok ? "Notification created" : "Failed to create"));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Boolean>> markAsRead(@PathVariable String id) {
        boolean ok = notificationService.markAsRead(id);
        return ResponseEntity.ok(ApiResponse.success(ok, ok ? "Marked as read" : "Failed to update"));
    }

    @PutMapping("/read-all")
    public ResponseEntity<ApiResponse<Boolean>> markAllAsRead(@RequestParam(required = false, defaultValue = "") String email) {
        if (email.trim().isEmpty()) {
            return ResponseEntity.ok(ApiResponse.success(true, "No-op"));
        }
        boolean ok = notificationService.markAllAsRead(email.trim());
        return ResponseEntity.ok(ApiResponse.success(ok, ok ? "All marked as read" : "Failed to update"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Boolean>> deleteNotification(@PathVariable String id) {
        boolean ok = notificationService.deleteNotification(id);
        return ResponseEntity.ok(ApiResponse.success(ok, ok ? "Deleted notification" : "Failed to delete"));
    }
}

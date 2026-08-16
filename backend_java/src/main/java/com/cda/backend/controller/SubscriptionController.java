package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.SubscriptionInfo;
import com.cda.backend.service.SubscriptionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/subscription")
@CrossOrigin(origins = "*")
public class SubscriptionController {

    @Autowired
    private SubscriptionService subscriptionService;

    @GetMapping
    public ResponseEntity<ApiResponse<SubscriptionInfo>> getSubscription(@RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        SubscriptionInfo info = subscriptionService.getSubscription(email);
        return ResponseEntity.ok(ApiResponse.success(info));
    }

    @PostMapping("/consume-trial")
    public ResponseEntity<ApiResponse<Boolean>> consumeTrial(@RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        boolean ok = subscriptionService.consumeTrial(email);
        return ResponseEntity.ok(ApiResponse.success("AI trial credit updated", ok));
    }

    @PostMapping("/upgrade-pro")
    public ResponseEntity<ApiResponse<Boolean>> upgradePro(@RequestParam(defaultValue = "unii12634@gmail.com") String email) {
        boolean ok = subscriptionService.upgradeToPro(email);
        return ResponseEntity.ok(ApiResponse.success("User upgraded to Pro successfully", ok));
    }
}

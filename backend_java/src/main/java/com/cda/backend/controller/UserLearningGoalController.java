package com.cda.backend.controller;

import com.cda.backend.model.UserLearningGoal;
import com.cda.backend.service.UserLearningGoalService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/user/goals")
@CrossOrigin(origins = "*")
public class UserLearningGoalController {

    @Autowired
    private UserLearningGoalService userLearningGoalService;

    @GetMapping
    public ResponseEntity<UserLearningGoal> getGoals(@RequestParam(name = "email", required = false) String email) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email : "unii12634@gmail.com";
        UserLearningGoal goal = userLearningGoalService.getLearningGoal(targetEmail);
        return ResponseEntity.ok(goal);
    }

    @PostMapping("/complete-today")
    public ResponseEntity<UserLearningGoal> completeToday(@RequestParam(name = "email", required = false) String email) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email : "unii12634@gmail.com";
        UserLearningGoal updated = userLearningGoalService.completeToday(targetEmail);
        return ResponseEntity.ok(updated);
    }
}

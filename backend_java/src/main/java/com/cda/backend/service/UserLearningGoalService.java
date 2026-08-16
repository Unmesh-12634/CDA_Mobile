package com.cda.backend.service;

import com.cda.backend.dao.UserLearningGoalsDAO;
import com.cda.backend.model.UserLearningGoal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserLearningGoalService {

    @Autowired
    private UserLearningGoalsDAO userLearningGoalsDAO;

    public UserLearningGoal getLearningGoal(String email) {
        return userLearningGoalsDAO.getLearningGoal(email);
    }

    public UserLearningGoal completeToday(String email) {
        return userLearningGoalsDAO.completeToday(email);
    }
}

package com.cda.backend.service;

import com.cda.backend.dao.UserActivitiesDAO;
import com.cda.backend.model.UserActivity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserActivityService {

    @Autowired
    private UserActivitiesDAO userActivitiesDAO;

    public List<UserActivity> getUserActivities(String email) {
        return userActivitiesDAO.findRecentActivitiesByUserEmail(email);
    }
}

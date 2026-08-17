package com.cda.backend.service;

import com.cda.backend.dao.AnalyticsDAO;
import com.cda.backend.model.UserAnalytics;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AnalyticsService {

    @Autowired
    private AnalyticsDAO analyticsDAO;

    public UserAnalytics getAnalytics(String email) {
        return analyticsDAO.getAnalytics(email);
    }
}

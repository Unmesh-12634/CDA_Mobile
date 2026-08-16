package com.cda.backend.service;

import com.cda.backend.dao.SubscriptionDAO;
import com.cda.backend.model.SubscriptionInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SubscriptionService {

    @Autowired
    private SubscriptionDAO subscriptionDAO;

    public SubscriptionInfo getSubscription(String email) {
        return subscriptionDAO.getSubscriptionByEmail(email);
    }

    public boolean consumeTrial(String email) {
        return subscriptionDAO.consumeTrial(email);
    }

    public boolean upgradeToPro(String email) {
        return subscriptionDAO.upgradeToPro(email);
    }
}

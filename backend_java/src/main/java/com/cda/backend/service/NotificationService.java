package com.cda.backend.service;

import com.cda.backend.dao.NotificationsDAO;
import com.cda.backend.model.Notification;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NotificationService {

    @Autowired
    private NotificationsDAO notificationsDAO;

    public List<Notification> getUserNotifications(String email) {
        if (email == null || email.trim().isEmpty()) {
            return List.of();
        }
        return notificationsDAO.findByUserEmail(email.trim());
    }

    public boolean createNotification(String email, String title, String message, String type, String actionUrl) {
        if (email == null || email.trim().isEmpty()) return false;
        return notificationsDAO.createNotification(email.trim(), title, message, type, actionUrl);
    }

    public boolean markAsRead(String id) {
        if (id == null || id.trim().isEmpty()) return false;
        return notificationsDAO.markAsRead(id.trim());
    }

    public boolean markAllAsRead(String email) {
        if (email == null || email.trim().isEmpty()) return false;
        return notificationsDAO.markAllAsRead(email.trim());
    }

    public boolean deleteNotification(String id) {
        if (id == null || id.trim().isEmpty()) return false;
        return notificationsDAO.deleteNotification(id.trim());
    }
}

package com.cda.backend.dao;

import com.cda.backend.model.Notification;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public class NotificationsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final RowMapper<Notification> NOTIF_MAPPER = new RowMapper<Notification>() {
        @Override
        public Notification mapRow(ResultSet rs, int rowNum) throws SQLException {
            Notification n = new Notification();
            n.setId(rs.getString("id"));
            n.setUserEmail(rs.getString("user_email"));
            n.setTitle(rs.getString("title"));
            n.setMessage(rs.getString("message"));
            n.setType(rs.getString("type"));
            n.setActionUrl(rs.getString("action_url"));
            n.setRead(rs.getBoolean("is_read"));
            n.setCreatedAt(rs.getString("created_at"));
            return n;
        }
    };

    public List<Notification> findByUserEmail(String email) {
        String sql = "SELECT * FROM public.notifications WHERE user_email = ? ORDER BY created_at DESC LIMIT 50";
        try {
            return jdbcTemplate.query(sql, NOTIF_MAPPER, email);
        } catch (Exception e) {
            return List.of();
        }
    }

    public boolean createNotification(String email, String title, String message, String type, String actionUrl) {
        String sql = "INSERT INTO public.notifications (id, user_email, title, message, type, action_url, is_read, created_at) " +
                     "VALUES (?, ?, ?, ?, ?, ?, false, ?)";
        String id = UUID.randomUUID().toString();
        String now = Instant.now().toString();
        try {
            int rows = jdbcTemplate.update(sql, id, email, title, message, type, actionUrl, now);
            return rows > 0;
        } catch (Exception e) {
            return false;
        }
    }

    public boolean markAsRead(String id) {
        String sql = "UPDATE public.notifications SET is_read = true WHERE id = ?";
        try {
            int rows = jdbcTemplate.update(sql, id);
            return rows > 0;
        } catch (Exception e) {
            return false;
        }
    }

    public boolean markAllAsRead(String email) {
        String sql = "UPDATE public.notifications SET is_read = true WHERE user_email = ?";
        try {
            int rows = jdbcTemplate.update(sql, email);
            return rows > 0;
        } catch (Exception e) {
            return false;
        }
    }

    public boolean deleteNotification(String id) {
        String sql = "DELETE FROM public.notifications WHERE id = ?";
        try {
            int rows = jdbcTemplate.update(sql, id);
            return rows > 0;
        } catch (Exception e) {
            return false;
        }
    }
}

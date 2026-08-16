package com.cda.backend.dao;

import com.cda.backend.model.SubscriptionInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class SubscriptionDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public SubscriptionInfo getSubscriptionByEmail(String email) {
        String sql = "SELECT ai_trials_remaining, ai_trials_total, is_pro_member FROM public.users WHERE email = ?";
        return jdbcTemplate.query(sql, rs -> {
            if (rs.next()) {
                int remaining = rs.getInt("ai_trials_remaining");
                int total = rs.getInt("ai_trials_total");
                boolean isPro = rs.getBoolean("is_pro_member");
                String plan = isPro ? "CDA Pro Unlimited" : "Standard Access";
                return new SubscriptionInfo(remaining, total, isPro, plan);
            }
            return new SubscriptionInfo(5, 5, false, "Standard Access");
        }, email);
    }

    public boolean consumeTrial(String email) {
        SubscriptionInfo info = getSubscriptionByEmail(email);
        if (info.isPro()) return true;
        if (info.getTrialsRemaining() <= 0) return false;

        String sql = "UPDATE public.users SET ai_trials_remaining = GREATEST(0, ai_trials_remaining - 1) WHERE email = ?";
        int rows = jdbcTemplate.update(sql, email);
        return rows > 0;
    }

    public boolean upgradeToPro(String email) {
        String sql = "UPDATE public.users SET is_pro_member = true WHERE email = ?";
        int rows = jdbcTemplate.update(sql, email);
        return rows > 0;
    }
}

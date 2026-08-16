package com.cda.backend.dao;

import com.cda.backend.model.SubscriptionInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Repository
public class SubscriptionDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public SubscriptionInfo getSubscriptionByEmail(String email) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email.trim() : "unii12634@gmail.com";
        String sql = "SELECT ai_trials_remaining, ai_trials_total, is_pro_member, pro_plan, pro_started_at, pro_expires_at FROM public.users WHERE email = ?";
        try {
            return jdbcTemplate.query(sql, rs -> {
                if (rs.next()) {
                    int remaining = rs.getInt("ai_trials_remaining");
                    int total = rs.getInt("ai_trials_total");
                    boolean isPro = rs.getBoolean("is_pro_member");
                    String plan = rs.getString("pro_plan");
                    if (plan == null || plan.isEmpty()) {
                        plan = isPro ? "CDA Pro Unlimited" : "Standard Access";
                    }

                    java.sql.Timestamp startTs = rs.getTimestamp("pro_started_at");
                    java.sql.Timestamp expireTs = rs.getTimestamp("pro_expires_at");

                    String startStr = startTs != null ? startTs.toInstant().toString() : null;
                    String expireStr = expireTs != null ? expireTs.toInstant().toString() : null;

                    long secondsRemaining = 0;
                    long daysRemaining = 0;
                    boolean isExpired = false;

                    if (isPro && expireTs != null) {
                        Instant now = Instant.now();
                        Instant expireInstant = expireTs.toInstant();

                        if (now.isAfter(expireInstant)) {
                            // Pro expired! Revert in DB
                            isPro = false;
                            isExpired = true;
                            plan = "Standard Access (Expired)";
                            revertExpiredPro(targetEmail);
                        } else {
                            Duration diff = Duration.between(now, expireInstant);
                            secondsRemaining = diff.getSeconds();
                            daysRemaining = diff.toDays();
                        }
                    }

                    return new SubscriptionInfo(
                            remaining, total, isPro, plan,
                            plan, startStr, expireStr,
                            secondsRemaining, daysRemaining, isExpired
                    );
                }
                return new SubscriptionInfo(5, 5, false, "Standard Access", "free", null, null, 0, 0, false);
            }, targetEmail);
        } catch (Exception e) {
            return new SubscriptionInfo(5, 5, false, "Standard Access", "free", null, null, 0, 0, false);
        }
    }

    public boolean consumeTrial(String email) {
        SubscriptionInfo info = getSubscriptionByEmail(email);
        if (info.isPro()) return true;
        if (info.getTrialsRemaining() <= 0) return false;

        String sql = "UPDATE public.users SET ai_trials_remaining = GREATEST(0, ai_trials_remaining - 1) WHERE email = ?";
        try {
            int rows = jdbcTemplate.update(sql, email);
            return rows > 0;
        } catch (Exception e) {
            return true;
        }
    }

    public boolean upgradeToPro(String email, String planCycle) {
        String targetEmail = (email != null && !email.trim().isEmpty()) ? email.trim() : "unii12634@gmail.com";
        String cycle = (planCycle != null && !planCycle.trim().isEmpty()) ? planCycle.toLowerCase().trim() : "1_month";

        Instant now = Instant.now();
        Instant expiresAt;
        String planTitle;

        if (cycle.contains("hour") || cycle.equals("1_hour")) {
            expiresAt = now.plus(1, ChronoUnit.HOURS);
            planTitle = "CDA Pro (1-Hour Pass)";
        } else if (cycle.contains("day") || cycle.equals("1_day")) {
            expiresAt = now.plus(1, ChronoUnit.DAYS);
            planTitle = "CDA Pro (1-Day Pass)";
        } else if (cycle.contains("3_month") || cycle.equals("quarterly")) {
            expiresAt = now.plus(90, ChronoUnit.DAYS);
            planTitle = "CDA Pro (3-Month Quarter)";
        } else if (cycle.contains("year") || cycle.equals("yearly") || cycle.equals("annual")) {
            expiresAt = now.plus(365, ChronoUnit.DAYS);
            planTitle = "CDA Pro (1-Year Annual)";
        } else {
            // Default 1 month
            expiresAt = now.plus(30, ChronoUnit.DAYS);
            planTitle = "CDA Pro (1-Month Monthly)";
        }

        try {
            String sql = "UPDATE public.users SET is_pro_member = true, role = 'Pro', ai_trials_remaining = 9999, " +
                         "pro_plan = ?, pro_started_at = ?, pro_expires_at = ? WHERE email = ?";
            
            java.sql.Timestamp startTs = java.sql.Timestamp.from(now);
            java.sql.Timestamp expireTs = java.sql.Timestamp.from(expiresAt);

            int rows = jdbcTemplate.update(sql, planTitle, startTs, expireTs, targetEmail);

            // Record in user_subscriptions timeline table
            try {
                String subHistorySql = "INSERT INTO public.user_subscriptions (id, user_email, plan_name, billing_cycle, status, started_at, expires_at) " +
                                       "VALUES (gen_random_uuid(), ?, ?, ?, 'Active', ?, ?)";
                jdbcTemplate.update(subHistorySql, targetEmail, planTitle, cycle, startTs, expireTs);
            } catch (Exception ignored) {}

            // Generate real notification
            String notifSql = "INSERT INTO public.notifications (user_email, title, body, type, is_read) VALUES (?, ?, ?, ?, ?)";
            jdbcTemplate.update(notifSql, targetEmail, "🎉 " + planTitle + " Activated!",
                    "Your membership is active until " + expiresAt.toString().split("T")[0] + ". Enjoy unlimited AI Mock Interviews, FAANG Pass, and Fast-Track applications.",
                    "subscription", false);

            return rows > 0;
        } catch (Exception e) {
            return true;
        }
    }

    private void revertExpiredPro(String email) {
        try {
            String sql = "UPDATE public.users SET is_pro_member = false, role = 'User', pro_plan = 'Standard Access', ai_trials_remaining = 5 WHERE email = ?";
            jdbcTemplate.update(sql, email);

            String notifSql = "INSERT INTO public.notifications (user_email, title, body, type, is_read) VALUES (?, ?, ?, ?, ?)";
            jdbcTemplate.update(notifSql, email, "⚠️ CDA Pro Membership Expired",
                    "Your CDA Pro pass period has ended. You can renew your subscription anytime to unlock unlimited interviews.",
                    "subscription", false);
        } catch (Exception ignored) {}
    }
}

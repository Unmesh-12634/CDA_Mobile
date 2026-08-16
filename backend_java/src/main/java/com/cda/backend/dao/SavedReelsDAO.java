package com.cda.backend.dao;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public class SavedReelsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<String> getSavedReelIds() {
        String sql = "SELECT reel_id FROM public.saved_reels";
        return jdbcTemplate.queryForList(sql, String.class);
    }

    public boolean toggleSave(String reelId) {
        String checkSql = "SELECT COUNT(*) FROM public.saved_reels WHERE reel_id = ?";
        Integer count = jdbcTemplate.queryForObject(checkSql, Integer.class, reelId);

        if (count != null && count > 0) {
            String delSql = "DELETE FROM public.saved_reels WHERE reel_id = ?";
            jdbcTemplate.update(delSql, reelId);
            return false;
        } else {
            String insSql = "INSERT INTO public.saved_reels (id, reel_id, created_at) VALUES (?, ?, ?)";
            jdbcTemplate.update(insSql, UUID.randomUUID().toString(), reelId, Instant.now().toString());
            return true;
        }
    }
}

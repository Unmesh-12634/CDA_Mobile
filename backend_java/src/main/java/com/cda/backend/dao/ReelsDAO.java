package com.cda.backend.dao;

import com.cda.backend.model.Reel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Array;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@Repository
public class ReelsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final RowMapper<Reel> REEL_MAPPER = new RowMapper<Reel>() {
        @Override
        public Reel mapRow(ResultSet rs, int rowNum) throws SQLException {
            Reel r = new Reel();
            r.setId(rs.getString("id"));
            r.setTitle(rs.getString("title"));
            r.setDescription(rs.getString("description"));
            r.setVideoUrl(rs.getString("video_url"));
            r.setThumbnailUrl(rs.getString("thumbnail_url"));
            r.setDurationSeconds(rs.getInt("duration_seconds"));
            r.setCategory(rs.getString("category"));
            r.setAuthorName(rs.getString("author_name"));
            r.setViewsCount(rs.getInt("views_count"));
            r.setLikesCount(rs.getInt("likes_count"));
            try {
                r.setCommentsCount(rs.getInt("comments_count"));
            } catch (Exception ignored) {}

            Array tagsArr = rs.getArray("tags");
            if (tagsArr != null) {
                String[] tags = (String[]) tagsArr.getArray();
                r.setTags(Arrays.asList(tags));
            } else {
                r.setTags(Collections.singletonList("Tech"));
            }
            return r;
        }
    };

    public List<Reel> findTopReels(int limit, String skill) {
        String sql = "SELECT * FROM public.reels WHERE is_active = true ORDER BY views_count DESC LIMIT ?";
        List<Reel> all = jdbcTemplate.query(sql, REEL_MAPPER, limit > 0 ? limit : 20);

        if (skill == null || skill.equalsIgnoreCase("All") || skill.trim().isEmpty()) {
            return all;
        }

        final String target = skill.trim().toLowerCase();
        List<Reel> filtered = all.stream().filter(r ->
                (r.getCategory() != null && r.getCategory().toLowerCase().contains(target)) ||
                (r.getTitle() != null && r.getTitle().toLowerCase().contains(target)) ||
                (r.getTags() != null && r.getTags().stream().anyMatch(t -> t.toLowerCase().contains(target)))
        ).toList();

        return filtered.isEmpty() ? all : filtered;
    }

    public boolean toggleLike(String reelId, String email) {
        try {
            String checkSql = "SELECT COUNT(*) FROM public.reel_likes WHERE reel_id = ? AND user_email = ?";
            Integer count = jdbcTemplate.queryForObject(checkSql, Integer.class, reelId, email);
            if (count != null && count > 0) {
                jdbcTemplate.update("DELETE FROM public.reel_likes WHERE reel_id = ? AND user_email = ?", reelId, email);
                return false;
            } else {
                jdbcTemplate.update("INSERT INTO public.reel_likes (reel_id, user_email) VALUES (?, ?) ON CONFLICT DO NOTHING", reelId, email);
                return true;
            }
        } catch (Exception e) {
            return false;
        }
    }

    public List<java.util.Map<String, Object>> getComments(String reelId) {
        String sql = "SELECT * FROM public.reel_comments WHERE reel_id = ? ORDER BY created_at DESC";
        return jdbcTemplate.queryForList(sql, reelId);
    }

    public java.util.Map<String, Object> addComment(String reelId, String email, String name, String avatar, String comment) {
        String sql = "INSERT INTO public.reel_comments (reel_id, user_email, user_name, user_avatar, comment, created_at) " +
                     "VALUES (?, ?, ?, ?, ?, NOW()) RETURNING *";
        return jdbcTemplate.queryForMap(sql, reelId, email, name, avatar, comment);
    }
}

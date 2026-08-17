package com.cda.backend.dao;

import com.cda.backend.model.Course;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Array;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@Repository
public class CoursesDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final RowMapper<Course> COURSE_MAPPER = new RowMapper<Course>() {
        @Override
        public Course mapRow(ResultSet rs, int rowNum) throws SQLException {
            Course c = new Course();
            c.setId(rs.getString("id"));
            c.setTitle(rs.getString("title"));
            c.setCategory(rs.getString("category"));
            c.setDescription(rs.getString("description"));
            c.setLinkUrl(rs.getString("link_url"));
            c.setThumbnailUrl(rs.getString("thumbnail_url"));
            c.setEstimatedDuration(rs.getString("estimated_duration"));
            c.setDifficultyLevel(rs.getString("difficulty_level"));
            c.setPriority(rs.getString("priority"));
            c.setFeatured(rs.getBoolean("is_featured"));
            c.setActive(rs.getBoolean("is_active"));

            Array tagsArray = rs.getArray("tags");
            if (tagsArray != null) {
                String[] tags = (String[]) tagsArray.getArray();
                c.setTags(Arrays.asList(tags));
            } else {
                c.setTags(Collections.emptyList());
            }
            return c;
        }
    };

    public List<Course> findAllActive() {
        try {
            String sql = "SELECT * FROM public.cda_courses WHERE is_active = true ORDER BY is_featured DESC, created_at ASC";
            return jdbcTemplate.query(sql, COURSE_MAPPER);
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    public List<Course> findFeatured() {
        try {
            String sql = "SELECT * FROM public.cda_courses WHERE is_active = true AND is_featured = true ORDER BY created_at ASC";
            return jdbcTemplate.query(sql, COURSE_MAPPER);
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    public List<Course> findByCategory(String category) {
        try {
            String sql = "SELECT * FROM public.cda_courses WHERE is_active = true AND LOWER(category) LIKE LOWER(?) ORDER BY created_at ASC";
            return jdbcTemplate.query(sql, COURSE_MAPPER, "%" + category + "%");
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    public Course findById(String id) {
        try {
            String sql = "SELECT * FROM public.cda_courses WHERE id = ?::uuid";
            List<Course> list = jdbcTemplate.query(sql, COURSE_MAPPER, id);
            return list.isEmpty() ? null : list.get(0);
        } catch (Exception e) {
            return null;
        }
    }
}

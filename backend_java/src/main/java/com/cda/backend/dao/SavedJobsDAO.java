package com.cda.backend.dao;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public class SavedJobsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public List<String> getSavedJobIds() {
        String sql = "SELECT job_id FROM public.saved_jobs";
        return jdbcTemplate.queryForList(sql, String.class);
    }

    public boolean toggleSave(String jobId) {
        String checkSql = "SELECT COUNT(*) FROM public.saved_jobs WHERE job_id = ?";
        Integer count = jdbcTemplate.queryForObject(checkSql, Integer.class, jobId);

        if (count != null && count > 0) {
            String delSql = "DELETE FROM public.saved_jobs WHERE job_id = ?";
            jdbcTemplate.update(delSql, jobId);
            return false;
        } else {
            String insSql = "INSERT INTO public.saved_jobs (id, job_id, created_at) VALUES (?, ?, ?)";
            jdbcTemplate.update(insSql, UUID.randomUUID().toString(), jobId, Instant.now().toString());
            return true;
        }
    }
}

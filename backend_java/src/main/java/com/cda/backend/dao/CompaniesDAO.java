package com.cda.backend.dao;

import com.cda.backend.model.Company;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;

@Repository
public class CompaniesDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final RowMapper<Company> COMPANY_MAPPER = new RowMapper<Company>() {
        @Override
        public Company mapRow(ResultSet rs, int rowNum) throws SQLException {
            Company c = new Company();
            c.setId(rs.getString("id"));
            c.setName(rs.getString("name"));
            c.setLogoUrl(rs.getString("logo_url"));
            c.setWebsite(rs.getString("website"));
            c.setIndustry(rs.getString("industry"));
            c.setHeadquarters(rs.getString("headquarters"));
            c.setDescription(rs.getString("description"));
            c.setActive(rs.getBoolean("is_active"));
            return c;
        }
    };

    public List<Company> findAllActive() {
        try {
            String sql = "SELECT * FROM public.companies WHERE is_active = true ORDER BY name ASC";
            return jdbcTemplate.query(sql, COMPANY_MAPPER);
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    public Company findById(String id) {
        try {
            String sql = "SELECT * FROM public.companies WHERE id = ?";
            List<Company> results = jdbcTemplate.query(sql, COMPANY_MAPPER, id);
            return results.isEmpty() ? null : results.get(0);
        } catch (Exception e) {
            return null;
        }
    }
}

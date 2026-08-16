package com.cda.backend.dao;

import com.cda.backend.model.UserProfile;
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
import java.util.UUID;

@Repository
public class UserProfileDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final RowMapper<UserProfile> PROFILE_MAPPER = new RowMapper<UserProfile>() {
        @Override
        public UserProfile mapRow(ResultSet rs, int rowNum) throws SQLException {
            UserProfile p = new UserProfile();
            p.setId(rs.getString("id"));
            p.setFullName(rs.getString("full_name"));
            p.setEmail(rs.getString("email"));
            p.setPhone(rs.getString("phone"));
            p.setBio(rs.getString("bio"));
            p.setDegree(rs.getString("degree"));
            p.setBranch(rs.getString("branch"));
            p.setPassingYear(rs.getString("passing_year"));
            p.setEmailVerified(rs.getBoolean("email_verified"));
            p.setExperienceYears(rs.getInt("experience_years"));
            p.setGithubUrl(rs.getString("github_url"));
            p.setLinkedinUrl(rs.getString("linkedin_url"));
            p.setPortfolioUrl(rs.getString("portfolio_url"));
            p.setResumeUrl(rs.getString("resume_url"));

            Array skillsArray = rs.getArray("skills");
            if (skillsArray != null) {
                String[] skills = (String[]) skillsArray.getArray();
                p.setSkills(Arrays.asList(skills));
            } else {
                p.setSkills(Collections.emptyList());
            }
            return p;
        }
    };

    public UserProfile findByEmail(String email) {
        String sql = "SELECT * FROM public.users WHERE email = ? LIMIT 1";
        List<UserProfile> list = jdbcTemplate.query(sql, PROFILE_MAPPER, email);
        return list.isEmpty() ? null : list.get(0);
    }

    public boolean saveOrUpdate(UserProfile profile) {
        UserProfile existing = findByEmail(profile.getEmail());
        String[] skillsArr = profile.getSkills() != null ? profile.getSkills().toArray(new String[0]) : new String[0];

        if (existing != null) {
            String sql = "UPDATE public.users SET full_name = ?, phone = ?, bio = ?, degree = ?, branch = ?, " +
                         "passing_year = ?, experience_years = ?, github_url = ?, linkedin_url = ?, " +
                         "portfolio_url = ?, resume_url = ?, skills = ? WHERE email = ?";
            int rows = jdbcTemplate.update(sql,
                    profile.getFullName(),
                    profile.getPhone(),
                    profile.getBio(),
                    profile.getDegree(),
                    profile.getBranch(),
                    profile.getPassingYear(),
                    profile.getExperienceYears(),
                    profile.getGithubUrl(),
                    profile.getLinkedinUrl(),
                    profile.getPortfolioUrl(),
                    profile.getResumeUrl(),
                    skillsArr,
                    profile.getEmail());
            return rows > 0;
        } else {
            String sql = "INSERT INTO public.users (id, full_name, email, phone, bio, degree, branch, passing_year, " +
                         "experience_years, github_url, linkedin_url, portfolio_url, resume_url, skills) " +
                         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            String newId = UUID.randomUUID().toString();
            int rows = jdbcTemplate.update(sql,
                    newId,
                    profile.getFullName(),
                    profile.getEmail(),
                    profile.getPhone(),
                    profile.getBio(),
                    profile.getDegree(),
                    profile.getBranch(),
                    profile.getPassingYear(),
                    profile.getExperienceYears(),
                    profile.getGithubUrl(),
                    profile.getLinkedinUrl(),
                    profile.getPortfolioUrl(),
                    profile.getResumeUrl(),
                    skillsArr);
            return rows > 0;
        }
    }
}

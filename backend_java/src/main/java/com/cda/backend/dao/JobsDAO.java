package com.cda.backend.dao;

import com.cda.backend.model.Job;
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
public class JobsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final RowMapper<Job> JOB_MAPPER = new RowMapper<Job>() {
        @Override
        public Job mapRow(ResultSet rs, int rowNum) throws SQLException {
            Job j = new Job();
            j.setId(rs.getString("id"));
            j.setTitle(rs.getString("title"));
            
            String company = rs.getString("company_name");
            j.setCompany(company != null ? company : "Tech Partner");
            j.setLocation(rs.getString("location"));
            
            String type = rs.getString("job_type");
            j.setType(type != null ? type : "Full-time");
            
            String salary = rs.getString("salary_display");
            j.setSalary(salary != null ? salary : "Competitive");
            
            String logo = company != null && !company.isEmpty()
                    ? Arrays.stream(company.split(" ")).map(e -> e.length() > 0 ? e.substring(0,1) : "").limit(2).reduce("", String::concat).toUpperCase()
                    : "CD";
            j.setLogoText(logo.isEmpty() ? "CD" : logo);
            
            j.setCategory(rs.getString("job_category"));
            j.setMatchScore(92);
            j.setPostedAgo("Active Opening");
            j.setExperienceLevel("All Levels");
            j.setDescription(rs.getString("description"));
            
            j.setResponsibilities(Arrays.asList(
                    "Architect and deliver scalable software systems",
                    "Collaborate across product and engineering teams",
                    "Maintain clean, performant, and reliable code"
            ));
            
            j.setRequirements(Arrays.asList(
                    "Strong technical fundamentals & domain expertise",
                    "Experience working in modern product environments",
                    "Proven track record of high-quality software delivery"
            ));

            Array skillsArray = rs.getArray("required_skills");
            if (skillsArray != null) {
                String[] skills = (String[]) skillsArray.getArray();
                j.setTags(Arrays.asList(skills));
            } else {
                j.setTags(Collections.singletonList("Tech"));
            }
            return j;
        }
    };

    public List<Job> findAllJobs(String category, String query) {
        String sql = "SELECT * FROM public.jobs WHERE is_active = true ORDER BY created_at DESC";
        List<Job> all = jdbcTemplate.query(sql, JOB_MAPPER);

        if ((category == null || category.equalsIgnoreCase("All")) && (query == null || query.trim().isEmpty())) {
            return all;
        }

        final String q = query != null ? query.trim().toLowerCase() : "";
        final String cat = category != null ? category.trim().toLowerCase() : "all";

        return all.stream().filter(j -> {
            boolean matchesCategory = cat.equals("all") ||
                    (cat.equals("remote") && j.getLocation() != null && j.getLocation().toLowerCase().contains("remote")) ||
                    (cat.equals("full-time") && j.getType() != null && j.getType().toLowerCase().contains("full")) ||
                    (cat.equals("internship") && j.getType() != null && j.getType().toLowerCase().contains("intern")) ||
                    (j.getCategory() != null && j.getCategory().toLowerCase().contains(cat)) ||
                    j.getTags().stream().anyMatch(t -> t.toLowerCase().contains(cat));

            boolean matchesQuery = q.isEmpty() ||
                    j.getTitle().toLowerCase().contains(q) ||
                    j.getCompany().toLowerCase().contains(q) ||
                    (j.getDescription() != null && j.getDescription().toLowerCase().contains(q)) ||
                    j.getTags().stream().anyMatch(t -> t.toLowerCase().contains(q));

            return matchesCategory && matchesQuery;
        }).toList();
    }

    public List<String> findTrendingSkills() {
        String sql = "SELECT DISTINCT unnest(required_skills) as skill, COUNT(*) as count " +
                     "FROM public.jobs WHERE is_active = true " +
                     "GROUP BY skill ORDER BY count DESC LIMIT 10";
        try {
            List<String> skills = jdbcTemplate.query(sql, (rs, rowNum) -> rs.getString("skill"));
            List<String> result = new ArrayList<>();
            result.add("All");
            result.addAll(skills);
            return result;
        } catch (Exception e) {
            return Arrays.asList("All", "Python", "Flutter", "PostgreSQL", "PyTorch", "UI/UX", "Java", "React");
        }
    }

    public Job findJobById(String id) {
        String sql = "SELECT * FROM public.jobs WHERE id = ?::uuid";
        List<Job> list = jdbcTemplate.query(sql, JOB_MAPPER, id);
        return list.isEmpty() ? null : list.get(0);
    }
}

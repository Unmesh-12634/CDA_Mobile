package com.cda.backend.dao;

import com.cda.backend.model.JobApplication;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Repository
public class ApplicationsDAO {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final RowMapper<JobApplication> APP_MAPPER = new RowMapper<JobApplication>() {
        @Override
        public JobApplication mapRow(ResultSet rs, int rowNum) throws SQLException {
            JobApplication app = new JobApplication();
            app.setId(rs.getString("id"));
            app.setJobId(rs.getString("job_id"));
            app.setUserId(rs.getString("user_id"));
            app.setApplicantEmail(rs.getString("applicant_email"));
            app.setStatus(rs.getString("status"));
            app.setResumeUrl(rs.getString("resume_url"));
            app.setAppliedAt(rs.getString("applied_at"));

            String company = rs.getString("company_name");
            app.setCompanyName(company != null ? company : "Tech Partner");
            app.setJobTitle(rs.getString("title"));
            app.setLocation(rs.getString("location"));
            app.setSalary(rs.getString("salary_display"));

            String logo = company != null && !company.isEmpty()
                    ? Arrays.stream(company.split(" ")).map(e -> e.length() > 0 ? e.substring(0,1) : "").limit(2).reduce("", String::concat).toUpperCase()
                    : "CD";
            app.setLogoText(logo.isEmpty() ? "CD" : logo);

            return app;
        }
    };

    public List<JobApplication> findByApplicantEmail(String email) {
        String sql = "SELECT a.*, j.company_name, j.title, j.location, j.salary_display " +
                     "FROM public.job_applications a " +
                     "LEFT JOIN public.jobs j ON a.job_id = j.id " +
                     "WHERE a.applicant_email = ? " +
                     "ORDER BY a.applied_at DESC";
        return jdbcTemplate.query(sql, APP_MAPPER, email);
    }

    public boolean apply(String jobId, String applicantEmail, String resumeUrl) {
        String sql = "INSERT INTO public.job_applications (id, job_id, applicant_email, resume_url, status, applied_at) " +
                     "VALUES (?, ?, ?, ?, 'Applied', ?)";
        String id = UUID.randomUUID().toString();
        String now = Instant.now().toString();
        int rows = jdbcTemplate.update(sql, id, jobId, applicantEmail, resumeUrl, now);
        return rows > 0;
    }

    public boolean updateStatus(String applicationId, String newStatus) {
        String sql = "UPDATE public.job_applications SET status = ?, updated_at = ? WHERE id = ?";
        String now = Instant.now().toString();
        int rows = jdbcTemplate.update(sql, newStatus, now, applicationId);
        return rows > 0;
    }
}

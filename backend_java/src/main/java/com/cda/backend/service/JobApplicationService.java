package com.cda.backend.service;

import com.cda.backend.dao.ApplicationsDAO;
import com.cda.backend.exception.BusinessException;
import com.cda.backend.model.JobApplication;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class JobApplicationService {

    @Autowired
    private ApplicationsDAO applicationsDAO;

    public List<JobApplication> getUserApplications(String email) {
        if (email == null || email.trim().isEmpty()) {
            throw new BusinessException("Applicant email is required.");
        }
        return applicationsDAO.findByApplicantEmail(email.trim());
    }

    public boolean apply(String jobId, String email, String resumeUrl) {
        if (jobId == null || jobId.trim().isEmpty()) {
            throw new BusinessException("Job ID is required to apply.");
        }
        if (email == null || email.trim().isEmpty()) {
            throw new BusinessException("Applicant email is required.");
        }
        return applicationsDAO.apply(jobId.trim(), email.trim(), resumeUrl);
    }

    public boolean updateStatus(String applicationId, String status) {
        if (applicationId == null || applicationId.trim().isEmpty()) {
            throw new BusinessException("Application ID is required.");
        }
        if (status == null || status.trim().isEmpty()) {
            throw new BusinessException("New application status is required.");
        }
        return applicationsDAO.updateStatus(applicationId.trim(), status.trim());
    }
}

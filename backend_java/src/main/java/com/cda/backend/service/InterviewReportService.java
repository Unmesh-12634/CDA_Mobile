package com.cda.backend.service;

import com.cda.backend.dao.InterviewReportDAO;
import com.cda.backend.model.InterviewReport;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class InterviewReportService {

    @Autowired
    private InterviewReportDAO interviewReportDAO;

    public List<InterviewReport> getReports(String email) {
        if (email == null || email.trim().isEmpty()) return List.of();
        return interviewReportDAO.findReportsByEmail(email.trim());
    }

    public boolean saveReport(String email, String targetRole, double overallScore, String feedbackSummary, List<String> strengths, List<String> improvements, String detailedQaJson, int durationSeconds) {
        return interviewReportDAO.saveReport(email, targetRole, overallScore, feedbackSummary, strengths, improvements, detailedQaJson, durationSeconds);
    }
}

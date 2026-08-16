package com.cda.backend.dto;

public class ApplicationRequest {
    private String jobId;
    private String email;
    private String resumeUrl;

    public ApplicationRequest() {}

    public String getJobId() { return jobId; }
    public void setJobId(String jobId) { this.jobId = jobId; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getResumeUrl() { return resumeUrl; }
    public void setResumeUrl(String resumeUrl) { this.resumeUrl = resumeUrl; }
}

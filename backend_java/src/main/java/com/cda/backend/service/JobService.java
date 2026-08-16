package com.cda.backend.service;

import com.cda.backend.dao.JobsDAO;
import com.cda.backend.exception.ResourceNotFoundException;
import com.cda.backend.model.Job;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class JobService {

    @Autowired
    private JobsDAO jobsDAO;

    public List<Job> getJobs(String category, String query) {
        return jobsDAO.findAllJobs(category, query);
    }

    public List<String> getTrendingSkills() {
        return jobsDAO.findTrendingSkills();
    }

    public Job getJobById(String id) {
        Job job = jobsDAO.findJobById(id);
        if (job == null) {
            throw new ResourceNotFoundException("Job with ID " + id + " was not found");
        }
        return job;
    }
}

package com.cda.backend.service;

import com.cda.backend.dao.SavedJobsDAO;
import com.cda.backend.dao.SavedReelsDAO;
import com.cda.backend.exception.BusinessException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BookmarkService {

    @Autowired
    private SavedJobsDAO savedJobsDAO;

    @Autowired
    private SavedReelsDAO savedReelsDAO;

    public List<String> getSavedJobIds() {
        return savedJobsDAO.getSavedJobIds();
    }

    public boolean toggleSaveJob(String jobId) {
        if (jobId == null || jobId.trim().isEmpty()) {
            throw new BusinessException("Job ID is required.");
        }
        return savedJobsDAO.toggleSave(jobId.trim());
    }

    public List<String> getSavedReelIds() {
        return savedReelsDAO.getSavedReelIds();
    }

    public boolean toggleSaveReel(String reelId) {
        if (reelId == null || reelId.trim().isEmpty()) {
            throw new BusinessException("Reel ID is required.");
        }
        return savedReelsDAO.toggleSave(reelId.trim());
    }
}

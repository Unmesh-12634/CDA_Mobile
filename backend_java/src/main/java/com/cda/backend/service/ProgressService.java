package com.cda.backend.service;

import com.cda.backend.dao.ProgressDAO;
import com.cda.backend.model.UserProgress;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ProgressService {

    @Autowired
    private ProgressDAO progressDAO;

    public UserProgress getProgress(String email) {
        UserProgress progress = progressDAO.getProgressByEmail(email);
        if (progress == null) {
            return new UserProgress(1, java.util.Arrays.asList(false, false, false, false, false, false, false), 0, java.time.LocalDate.now().toString());
        }
        return progress;
    }

    public boolean completeToday(String email) {
        return progressDAO.completeToday(email);
    }
}

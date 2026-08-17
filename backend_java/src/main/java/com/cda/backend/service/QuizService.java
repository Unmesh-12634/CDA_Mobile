package com.cda.backend.service;

import com.cda.backend.dao.QuizDAO;
import com.cda.backend.model.QuizResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class QuizService {

    @Autowired
    private QuizDAO quizDAO;

    public boolean saveResult(String email, int score, int correctCount, int totalQuestions,
                              String category, String skillFocus) {
        return quizDAO.saveResult(email, score, correctCount, totalQuestions, category, skillFocus);
    }

    public List<QuizResult> getHistory(String email) {
        return quizDAO.fetchHistory(email, 20);
    }
}

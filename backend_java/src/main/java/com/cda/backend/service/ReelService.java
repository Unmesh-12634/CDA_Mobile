package com.cda.backend.service;

import com.cda.backend.dao.ReelsDAO;
import com.cda.backend.model.Reel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ReelService {

    @Autowired
    private ReelsDAO reelsDAO;

    public List<Reel> getTopReels(int limit, String skill) {
        return reelsDAO.findTopReels(limit, skill);
    }

    public boolean toggleLike(String reelId, String email) {
        return reelsDAO.toggleLike(reelId, email);
    }

    public List<java.util.Map<String, Object>> getComments(String reelId) {
        return reelsDAO.getComments(reelId);
    }

    public java.util.Map<String, Object> addComment(String reelId, String email, String name, String avatar, String comment) {
        return reelsDAO.addComment(reelId, email, name, avatar, comment);
    }
}

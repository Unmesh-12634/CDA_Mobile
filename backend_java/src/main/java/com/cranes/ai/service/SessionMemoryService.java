package com.cranes.ai.service;

import com.cranes.ai.model.InterviewModels.ActivityLogEntry;
import com.cranes.ai.model.InterviewModels.StartInterviewRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class SessionMemoryService {

    public static class SessionData {
        public String sessionId;
        public StartInterviewRequest config;
        public int currentTurn = 1;
        public List<String> askedQuestions = new ArrayList<>();
        public List<String> candidateAnswers = new ArrayList<>();
        public List<Double> turnScores = new ArrayList<>();
        public List<String> turnFeedbacks = new ArrayList<>();
        public boolean isCompleted = false;
    }

    private final Map<String, SessionData> sessions = new ConcurrentHashMap<>();
    private final List<ActivityLogEntry> activityLogs = new CopyOnWriteArrayList<>();
    private final AtomicLong logCounter = new AtomicLong(1);

    public SessionMemoryService() {
        logActivity("SERVER_START", "System Java Backend", "Spring Boot AI Backend initialized on Port 8000", "SUCCESS", null);
    }

    public void logActivity(String eventType, String candidateName, String details, String level, String errorDetails) {
        ActivityLogEntry entry = new ActivityLogEntry();
        entry.id = logCounter.getAndIncrement();
        entry.timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
        entry.date = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        entry.eventType = eventType;
        entry.candidateName = candidateName != null ? candidateName : "Candidate";
        entry.details = details;
        entry.level = level != null ? level : "INFO";
        entry.errorDetails = errorDetails;

        activityLogs.add(0, entry);
        if (activityLogs.size() > 200) {
            activityLogs.remove(activityLogs.size() - 1);
        }
    }

    public SessionData createSession(StartInterviewRequest req) {
        SessionData s = new SessionData();
        s.sessionId = "session_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 6);
        s.config = req;
        sessions.put(s.sessionId, s);
        return s;
    }

    public SessionData getSession(String sessionId) {
        return sessions.get(sessionId);
    }

    public int getActiveSessionCount() {
        return sessions.size();
    }

    public List<ActivityLogEntry> getActivityLogs() {
        return Collections.unmodifiableList(activityLogs);
    }
}

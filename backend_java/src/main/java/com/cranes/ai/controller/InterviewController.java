package com.cranes.ai.controller;

import com.cranes.ai.model.InterviewModels;
import com.cranes.ai.model.InterviewModels.*;
import com.cranes.ai.service.GroqAiService;
import com.cranes.ai.service.SessionMemoryService;
import com.cranes.ai.service.SessionMemoryService.SessionData;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*")
public class InterviewController {

    private final GroqAiService groqAiService;
    private final SessionMemoryService sessionMemoryService;

    public InterviewController(GroqAiService groqAiService, SessionMemoryService sessionMemoryService) {
        this.groqAiService = groqAiService;
        this.sessionMemoryService = sessionMemoryService;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        sessionMemoryService.logActivity("HEALTH_CHECK", "Mobile Ping", "Health diagnostic check requested", "INFO", null);
        return ResponseEntity.ok(Map.of(
            "status", "online",
            "service", "Cranes Varsity Java AI Interview Engine",
            "framework", "Spring Boot 3.2 (Java 17)",
            "groq_api_key_configured", groqAiService.isApiKeyConfigured(),
            "active_sessions", sessionMemoryService.getActiveSessionCount()
        ));
    }

    @PostMapping("/interview/start")
    public ResponseEntity<StartInterviewResponse> startInterview(@RequestBody StartInterviewRequest req) {
        try {
            SessionData session = sessionMemoryService.createSession(req);
            String candidateName = (req.candidateName != null && !req.candidateName.trim().isEmpty()) ? req.candidateName.trim() : "Arjun Verma";

            String greeting = groqAiService.generateInitialGreeting(candidateName, req.jobRole, req.difficulty);
            String question1 = groqAiService.generateQuestion(candidateName, req.jobRole, req.difficulty, 1);

            session.askedQuestions.add(question1);

            StartInterviewResponse resp = new StartInterviewResponse();
            resp.sessionId = session.sessionId;
            resp.isCompleted = false;
            resp.initialGreeting = greeting;
            resp.currentQuestion = question1;
            resp.turnNumber = 1;
            resp.totalTargetQuestions = req.targetQuestionCount > 0 ? req.targetQuestionCount : 5;
            resp.transitionPhrase = "Let us begin with your technical evaluation.";

            sessionMemoryService.logActivity(
                "START_SESSION",
                candidateName,
                String.format("<b>Candidate:</b> %s | <b>Role:</b> %s | <b>Difficulty:</b> %s<br><b>AI Greeting:</b> %s<br><b>Question 1 Sent to Mobile:</b> %s",
                    candidateName, req.jobRole, req.difficulty, greeting, question1),
                "SUCCESS",
                null
            );

            return ResponseEntity.ok(resp);
        } catch (Exception e) {
            sessionMemoryService.logActivity("START_ERROR", req.candidateName, "Failed to start interview session", "ERROR", e.getMessage());
            throw new RuntimeException("Failed to start session: " + e.getMessage());
        }
    }

    @PostMapping("/interview/answer")
    public ResponseEntity<AnswerResponse> submitAnswer(@RequestBody AnswerRequest req) {
        try {
            SessionData session = sessionMemoryService.getSession(req.sessionId);
            String candidateName = (session != null && session.config != null) ? session.config.candidateName : "Candidate";

            int currentTurn = session != null ? session.currentTurn : 1;
            int totalTarget = session != null ? session.config.targetQuestionCount : 5;

            Map<String, Object> eval = groqAiService.evaluateAnswer(
                session != null && !session.askedQuestions.isEmpty() ? session.askedQuestions.get(session.askedQuestions.size() - 1) : "",
                req.candidateAnswer
            );

            double score = (double) eval.get("score");
            String feedback = (String) eval.get("feedback");

            if (session != null) {
                session.candidateAnswers.add(req.candidateAnswer);
                session.turnScores.add(score);
                session.turnFeedbacks.add(feedback);
                session.currentTurn++;
            }

            boolean isCompleted = (session != null && session.currentTurn > totalTarget);
            String nextQuestion = null;
            if (!isCompleted && session != null) {
                nextQuestion = groqAiService.generateQuestion(candidateName, session.config.jobRole, session.config.difficulty, session.currentTurn);
                session.askedQuestions.add(nextQuestion);
            }

            AnswerResponse resp = new AnswerResponse();
            resp.sessionId = req.sessionId;
            resp.isCompleted = isCompleted;
            resp.currentQuestion = nextQuestion;
            resp.turnNumber = session != null ? session.currentTurn : currentTurn + 1;
            resp.totalTargetQuestions = totalTarget;
            resp.transitionPhrase = isCompleted ? "Technical interview round completed." : "Let us proceed to the next technical topic.";
            resp.lastEvaluationScore = score;
            resp.lastFeedback = feedback;
            resp.speechAnalytics = Map.of("wpm", 145, "filler_words", 0, "clarity_score", 92);

            sessionMemoryService.logActivity(
                "SUBMIT_ANSWER",
                candidateName,
                String.format("<b>Turn %d / %d</b><br><b>Candidate Answer:</b> \"%s\"<br><b>AI Score:</b> <span style='color:#10B981;font-weight:bold;'>%.1f/10</span> | <b>Feedback:</b> %s<br><b>Next Question Sent to Mobile:</b> %s",
                    currentTurn, totalTarget, req.candidateAnswer, score, feedback, nextQuestion != null ? nextQuestion : "Round Completed"),
                "INFO",
                null
            );

            return ResponseEntity.ok(resp);
        } catch (Exception e) {
            sessionMemoryService.logActivity("ANSWER_ERROR", req.sessionId, "Error processing candidate answer", "ERROR", e.getMessage());
            throw new RuntimeException("Failed to process answer: " + e.getMessage());
        }
    }

    @GetMapping("/monitor/logs")
    public ResponseEntity<Map<String, Object>> getMonitorLogs() {
        return ResponseEntity.ok(Map.of(
            "logs", sessionMemoryService.getActivityLogs(),
            "total", sessionMemoryService.getActivityLogs().size(),
            "active_sessions", sessionMemoryService.getActiveSessionCount(),
            "groq_status", groqAiService.isApiKeyConfigured() ? "online" : "fallback_mode"
        ));
    }

    @PostMapping("/interview/finish/{sessionId}")
    public ResponseEntity<InterviewModels.InterviewFinishResponse> finishInterview(@PathVariable String sessionId) {
        try {
            SessionData session = sessionMemoryService.getSession(sessionId);

            InterviewModels.InterviewFinishResponse resp = new InterviewModels.InterviewFinishResponse();
            resp.sessionId = sessionId;
            resp.isCompleted = true;

            if (session != null) {
                resp.scoresPerTurn = session.turnScores;
                resp.feedbacks = session.turnFeedbacks;
                resp.questions = session.askedQuestions;
                resp.answers = session.candidateAnswers;
                resp.totalQuestionsAsked = session.askedQuestions.size();

                double avg = session.turnScores.isEmpty() ? 7.5
                    : session.turnScores.stream().mapToDouble(Double::doubleValue).average().orElse(7.5);
                resp.overallScore = Math.round(avg * 10.0) / 10.0;

                String candidateName = session.config != null ? session.config.candidateName : "Candidate";
                resp.summary = String.format(
                    "%s completed %d technical questions with an average score of %.1f/10. Performance: %s.",
                    candidateName, resp.totalQuestionsAsked, resp.overallScore,
                    resp.overallScore >= 8.0 ? "Excellent" : resp.overallScore >= 6.5 ? "Good" : "Needs Improvement"
                );

                sessionMemoryService.logActivity(
                    "FINISH_SESSION", session.config != null ? session.config.candidateName : "Candidate",
                    String.format("<b>Interview Completed!</b><br><b>Overall Score:</b> <span style='color:#10B981;font-weight:bold;'>%.1f/10</span> | <b>Questions Asked:</b> %d",
                        resp.overallScore, resp.totalQuestionsAsked),
                    "SUCCESS", null
                );
            } else {
                resp.overallScore = 7.5;
                resp.totalQuestionsAsked = 0;
                resp.summary = "Interview session completed.";
                resp.scoresPerTurn = java.util.Collections.emptyList();
                resp.feedbacks = java.util.Collections.emptyList();
                resp.questions = java.util.Collections.emptyList();
                resp.answers = java.util.Collections.emptyList();
            }

            return ResponseEntity.ok(resp);
        } catch (Exception e) {
            sessionMemoryService.logActivity("FINISH_ERROR", sessionId, "Error finishing interview session", "ERROR", e.getMessage());
            throw new RuntimeException("Failed to finish session: " + e.getMessage());
        }
    }
}

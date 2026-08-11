package com.cranes.ai.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;
import java.util.Map;

public class InterviewModels {

    public static class StartInterviewRequest {
        @JsonProperty("candidate_name")
        public String candidateName = "Arjun Verma";

        @JsonProperty("job_role")
        public String jobRole = "Senior AI & Full-Stack Engineer";

        @JsonProperty("experience_level")
        public String experienceLevel = "1 - 3 Years";

        @JsonProperty("interview_type")
        public String interviewType = "Technical";

        @JsonProperty("difficulty")
        public String difficulty = "Intermediate";

        @JsonProperty("target_question_count")
        public int targetQuestionCount = 5;

        @JsonProperty("voice_persona")
        public String voicePersona = "christopher";

        @JsonProperty("enrolled_courses")
        public List<String> enrolledCourses;

        @JsonProperty("skills")
        public List<String> skills;

        @JsonProperty("resume_path")
        public String resumePath;
    }

    public static class StartInterviewResponse {
        @JsonProperty("session_id")
        public String sessionId;

        @JsonProperty("is_completed")
        public boolean isCompleted;

        @JsonProperty("initial_greeting")
        public String initialGreeting;

        @JsonProperty("current_question")
        public String currentQuestion;

        @JsonProperty("turn_number")
        public int turnNumber;

        @JsonProperty("total_target_questions")
        public int totalTargetQuestions;

        @JsonProperty("transition_phrase")
        public String transitionPhrase;
    }

    public static class AnswerRequest {
        @JsonProperty("session_id")
        public String sessionId;

        @JsonProperty("candidate_answer")
        public String candidateAnswer;

        @JsonProperty("speaking_duration_sec")
        public Double speakingDurationSec = 15.0;
    }

    public static class AnswerResponse {
        @JsonProperty("session_id")
        public String sessionId;

        @JsonProperty("is_completed")
        public boolean isCompleted;

        @JsonProperty("current_question")
        public String currentQuestion;

        @JsonProperty("turn_number")
        public int turnNumber;

        @JsonProperty("total_target_questions")
        public int totalTargetQuestions;

        @JsonProperty("transition_phrase")
        public String transitionPhrase;

        @JsonProperty("last_evaluation_score")
        public Double lastEvaluationScore;

        @JsonProperty("last_feedback")
        public String lastFeedback;

        @JsonProperty("speech_analytics")
        public Map<String, Object> speechAnalytics;
    }

    public static class ActivityLogEntry {
        public long id;
        public String timestamp;
        public String date;
        public String eventType;
        public String candidateName;
        public String details;
        public String level;
        public String errorDetails;
    }

    public static class InterviewFinishResponse {
        @JsonProperty("session_id")
        public String sessionId;

        @JsonProperty("is_completed")
        public boolean isCompleted = true;

        @JsonProperty("overall_score")
        public double overallScore;

        @JsonProperty("total_questions_asked")
        public int totalQuestionsAsked;

        @JsonProperty("summary")
        public String summary;

        @JsonProperty("scores_per_turn")
        public List<Double> scoresPerTurn;

        @JsonProperty("feedbacks")
        public List<String> feedbacks;

        @JsonProperty("questions")
        public List<String> questions;

        @JsonProperty("answers")
        public List<String> answers;
    }
}

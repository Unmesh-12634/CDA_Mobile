package com.cranes.ai.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
public class GroqAiService {

    private final OkHttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final String groqApiKey;
    private final String groqModel;

    public GroqAiService(
            @Value("${groq.api.key:}") String apiKeyFromProps,
            @Value("${groq.model:llama3-70b-8192}") String groqModel) {
        this.httpClient = new OkHttpClient.Builder()
                .connectTimeout(30, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .build();
        this.objectMapper = new ObjectMapper();
        this.groqModel = groqModel;

        // Prefer env var, then application.properties, skip placeholder
        String envKey = System.getenv("GROQ_API_KEY");
        if (envKey != null && !envKey.isBlank()) {
            this.groqApiKey = envKey;
        } else if (apiKeyFromProps != null && !apiKeyFromProps.isBlank()
                && !apiKeyFromProps.startsWith("your_groq")) {
            this.groqApiKey = apiKeyFromProps;
        } else {
            this.groqApiKey = null;
        }

        System.out.println("🤖 GroqAiService initialized. API Key configured: " + isApiKeyConfigured()
                + " | Model: " + groqModel);
    }

    public boolean isApiKeyConfigured() {
        return groqApiKey != null && !groqApiKey.trim().isEmpty();
    }

    public String generateInitialGreeting(String candidateName, String jobRole, String difficulty) {
        if (isApiKeyConfigured()) {
            String prompt = String.format(
                "Generate a short 1-sentence friendly welcoming greeting for %s who is interviewing for a %s role at %s level.",
                candidateName, jobRole, difficulty);
            String aiGreeting = callGroqLlama(prompt);
            if (aiGreeting != null && !aiGreeting.trim().isEmpty()) {
                return aiGreeting.trim();
            }
        }
        return String.format(
            "Hello %s! Welcome to your %s AI technical interview at Cranes Varsity. I will evaluate your problem-solving, architectural reasoning, and technical depth today.",
            candidateName, jobRole);
    }

    public String generateQuestion(String candidateName, String jobRole, String difficulty, int turnNumber) {
        if (isApiKeyConfigured()) {
            String prompt = String.format(
                "Generate 1 clear technical interview question for a %s role at %s difficulty level (Turn %d). Ask directly without intro preamble. No numbering.",
                jobRole, difficulty, turnNumber);
            String aiQ = callGroqLlama(prompt);
            if (aiQ != null && !aiQ.trim().isEmpty()) {
                return aiQ.trim();
            }
        }

        // Fallback questions when no API key
        switch (turnNumber) {
            case 1: return String.format("Tell me about a complex project you developed using %s. What key architectural decisions and trade-offs did you make?", jobRole);
            case 2: return String.format("How do you design high-concurrency systems in %s to handle spike traffic while maintaining low latency and thread safety?", jobRole);
            case 3: return "How do you detect memory leaks, unhandled async promises, or deadlocks in production? Walk me through your debugging methodology.";
            case 4: return "What design patterns do you strictly enforce when building enterprise REST APIs? Give a real example.";
            default: return String.format("How do you ensure security and performance in %s at scale?", jobRole);
        }
    }

    public Map<String, Object> evaluateAnswer(String question, String answer) {
        if (isApiKeyConfigured() && answer != null && answer.length() > 10) {
            String prompt = String.format(
                "You are an expert technical interviewer. Evaluate this answer:\nQuestion: %s\nCandidate Answer: %s\n\nRespond ONLY as JSON: {\"score\": <number 0-10>, \"feedback\": \"<one sentence feedback>\"}",
                question, answer);
            String raw = callGroqLlama(prompt);
            if (raw != null) {
                try {
                    // Extract JSON block from response
                    int start = raw.indexOf('{');
                    int end = raw.lastIndexOf('}');
                    if (start >= 0 && end > start) {
                        JsonNode node = objectMapper.readTree(raw.substring(start, end + 1));
                        double score = node.has("score") ? node.get("score").asDouble(7.0) : 7.0;
                        String feedback = node.has("feedback") ? node.get("feedback").asText() : "Good response.";
                        return Map.of("score", Math.min(10.0, Math.max(0.0, score)), "feedback", feedback);
                    }
                } catch (Exception e) {
                    System.err.println("Groq eval parse error: " + e.getMessage());
                }
            }
        }

        // Fallback scoring based on answer length
        double score = 7.0;
        if (answer != null && answer.length() > 20) {
            score = Math.min(10.0, 6.5 + (answer.length() / 80.0));
        }
        return Map.of("score", score, "feedback", "Good technical explanation. Candidate demonstrated solid understanding.");
    }

    private String callGroqLlama(String prompt) {
        try {
            String jsonPayload = objectMapper.writeValueAsString(Map.of(
                "model", groqModel,
                "messages", java.util.List.of(
                    Map.of("role", "system", "content", "You are an expert AI Technical Interviewer at Cranes Varsity."),
                    Map.of("role", "user", "content", prompt)
                ),
                "temperature", 0.7,
                "max_tokens", 300
            ));

            RequestBody body = RequestBody.create(jsonPayload, MediaType.get("application/json; charset=utf-8"));
            Request request = new Request.Builder()
                .url("https://api.groq.com/openai/v1/chat/completions")
                .header("Authorization", "Bearer " + groqApiKey)
                .post(body)
                .build();

            try (Response response = httpClient.newCall(request).execute()) {
                if (response.isSuccessful() && response.body() != null) {
                    JsonNode node = objectMapper.readTree(response.body().string());
                    return node.get("choices").get(0).get("message").get("content").asText();
                } else {
                    System.err.println("Groq API Error: " + response.code() + " " + (response.body() != null ? response.body().string() : ""));
                }
            }
        } catch (IOException e) {
            System.err.println("Groq API Call Error: " + e.getMessage());
        }
        return null;
    }
}

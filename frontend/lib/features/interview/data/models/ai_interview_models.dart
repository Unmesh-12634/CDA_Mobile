// ─────────────────────────────────────────────────────────────
// Request Models (Matching FastAPI Pydantic Schemas)
// ─────────────────────────────────────────────────────────────

class StartInterviewRequest {
  final String candidateName;
  final String jobRole;
  final String? jobDescription;
  final String experienceLevel;
  final String interviewType;
  final String difficulty;
  final int targetQuestionCount;
  final String? voicePersona;
  final List<String> enrolledCourses;
  final List<String> skills;
  final String? resumePath;
  final String? resumeText;

  StartInterviewRequest({
    required this.candidateName,
    required this.jobRole,
    this.jobDescription,
    required this.experienceLevel,
    required this.interviewType,
    required this.difficulty,
    this.targetQuestionCount = 5,
    this.voicePersona = 'guy',
    this.enrolledCourses = const [],
    this.skills = const [],
    this.resumePath,
    this.resumeText,
  });

  Map<String, dynamic> toJson() {
    return {
      'candidate_name': candidateName,
      'job_role': jobRole,
      if (jobDescription != null && jobDescription!.isNotEmpty) 'job_description': jobDescription,
      'experience_level': experienceLevel,
      'interview_type': interviewType,
      'difficulty': difficulty,
      'target_question_count': targetQuestionCount,
      'voice_persona': voicePersona ?? 'guy',
      'enrolled_courses': enrolledCourses,
      'skills': skills,
      if (resumePath != null && resumePath!.isNotEmpty) 'resume_path': resumePath,
      if (resumeText != null && resumeText!.isNotEmpty) 'resume_text': resumeText,
    };
  }
}

class AnswerRequest {
  final String sessionId;
  final String candidateAnswer;
  final double speakingDurationSec;

  AnswerRequest({
    required this.sessionId,
    required this.candidateAnswer,
    this.speakingDurationSec = 15.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'candidate_answer': candidateAnswer,
      'speaking_duration_sec': speakingDurationSec,
    };
  }
}

class TTSRequest {
  final String text;
  final String voicePersona;

  TTSRequest({
    required this.text,
    this.voicePersona = 'christopher',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'voice_persona': voicePersona,
    };
  }
}

// ─────────────────────────────────────────────────────────────
// Response Models (Matching FastAPI Pydantic Schemas)
// ─────────────────────────────────────────────────────────────

class StartInterviewResponse {
  final String sessionId;
  final bool isCompleted;
  final String initialGreeting;
  final String currentQuestion;
  final int turnNumber;
  final int totalTargetQuestions;
  final String transitionPhrase;

  StartInterviewResponse({
    required this.sessionId,
    required this.isCompleted,
    required this.initialGreeting,
    required this.currentQuestion,
    required this.turnNumber,
    required this.totalTargetQuestions,
    required this.transitionPhrase,
  });

  factory StartInterviewResponse.fromJson(Map<String, dynamic> json) {
    return StartInterviewResponse(
      sessionId: json['session_id'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      initialGreeting: json['initial_greeting'] ?? 'Welcome to your AI technical interview session.',
      currentQuestion: json['current_question'] ?? 'Tell me about your background and recent technical projects.',
      turnNumber: json['turn_number'] ?? 1,
      totalTargetQuestions: json['total_target_questions'] ?? 5,
      transitionPhrase: json['transition_phrase'] ?? 'Let us begin.',
    );
  }
}

class AnswerResponse {
  final String sessionId;
  final bool isCompleted;
  final String? currentQuestion;
  final int turnNumber;
  final int totalTargetQuestions;
  final String transitionPhrase;
  final double? lastEvaluationScore;
  final String? lastFeedback;
  final Map<String, dynamic>? speechAnalytics;

  AnswerResponse({
    required this.sessionId,
    required this.isCompleted,
    this.currentQuestion,
    required this.turnNumber,
    required this.totalTargetQuestions,
    required this.transitionPhrase,
    this.lastEvaluationScore,
    this.lastFeedback,
    this.speechAnalytics,
  });

  factory AnswerResponse.fromJson(Map<String, dynamic> json) {
    return AnswerResponse(
      sessionId: json['session_id'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      currentQuestion: json['current_question'] as String?,
      turnNumber: json['turn_number'] ?? 1,
      totalTargetQuestions: json['total_target_questions'] ?? 5,
      transitionPhrase: json['transition_phrase'] ?? 'Moving to the next question.',
      lastEvaluationScore: (json['last_evaluation_score'] as num?)?.toDouble(),
      lastFeedback: json['last_feedback'] as String?,
      speechAnalytics: json['speech_analytics'] as Map<String, dynamic>?,
    );
  }
}

class InterviewFinishResponse {
  final String sessionId;
  final double overallScore;
  final double technicalScore;
  final double communicationScore;
  final double problemSolvingScore;
  final String hiringReadiness;
  final bool isTerminatedEarly;
  final int completedTurns;
  final int targetTurns;
  final String summary;
  final List<String> strongAreas;
  final List<String> areasForImprovement;

  InterviewFinishResponse({
    required this.sessionId,
    required this.overallScore,
    required this.technicalScore,
    required this.communicationScore,
    required this.problemSolvingScore,
    required this.hiringReadiness,
    required this.isTerminatedEarly,
    required this.completedTurns,
    required this.targetTurns,
    required this.summary,
    required this.strongAreas,
    required this.areasForImprovement,
  });

  factory InterviewFinishResponse.fromJson(Map<String, dynamic> json) {
    return InterviewFinishResponse(
      sessionId: json['session_id'] ?? '',
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      technicalScore: (json['technical_score'] as num?)?.toDouble() ?? 0.0,
      communicationScore: (json['communication_score'] as num?)?.toDouble() ?? 0.0,
      problemSolvingScore: (json['problem_solving_score'] as num?)?.toDouble() ?? 0.0,
      hiringReadiness: json['hiring_readiness'] ?? 'EVALUATED',
      isTerminatedEarly: json['is_terminated_early'] ?? false,
      completedTurns: json['completed_turns'] ?? 0,
      targetTurns: json['target_turns'] ?? 5,
      summary: json['summary'] ?? 'Session analysis generated.',
      strongAreas: (json['strong_areas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      areasForImprovement: (json['areas_for_improvement'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'overall_score': overallScore,
      'technical_score': technicalScore,
      'communication_score': communicationScore,
      'problem_solving_score': problemSolvingScore,
      'hiring_readiness': hiringReadiness,
      'is_terminated_early': isTerminatedEarly,
      'completed_turns': completedTurns,
      'target_turns': targetTurns,
      'summary': summary,
      'strong_areas': strongAreas,
      'areas_for_improvement': areasForImprovement,
    };
  }
}

class ResumeParseResponse {
  final String status;
  final String candidateName;
  final List<String> skills;
  final List<String> projects;
  final List<String> hackathons;
  final List<String> certifications;
  final String experienceLevel;
  final String targetRole;

  ResumeParseResponse({
    required this.status,
    required this.candidateName,
    required this.skills,
    required this.projects,
    required this.hackathons,
    required this.certifications,
    required this.experienceLevel,
    required this.targetRole,
  });

  factory ResumeParseResponse.fromJson(Map<String, dynamic> json) {
    return ResumeParseResponse(
      status: json['status'] ?? 'success',
      candidateName: json['candidate_name'] ?? 'Candidate',
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      projects: (json['projects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      hackathons: (json['hackathons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      certifications: (json['certifications'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      experienceLevel: json['experience_level'] ?? 'Mid-Level',
      targetRole: json['target_role'] ?? 'Developer',
    );
  }
}

class HealthResponse {
  final String status;
  final String service;
  final String version;
  final String llmProvider;
  final bool groqApiKeyConfigured;
  final int latencyMs;

  HealthResponse({
    required this.status,
    required this.service,
    required this.version,
    required this.llmProvider,
    required this.groqApiKeyConfigured,
    required this.latencyMs,
  });

  bool get isHealthy => status.toLowerCase() == 'online' || status.toLowerCase() == 'healthy' || status.toLowerCase() == 'ok';


  factory HealthResponse.fromJson(Map<String, dynamic> json, int latencyMs) {
    return HealthResponse(
      status: json['status'] ?? 'offline',
      service: json['service'] ?? 'CDA AI Engine',
      version: json['version'] ?? '2.0.0',
      llmProvider: json['llm_provider'] ?? 'Groq Llama-3 70B',
      groqApiKeyConfigured: json['groq_api_key_configured'] ?? false,
      latencyMs: latencyMs,
    );
  }
}

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiInterviewSessionData {
  final String sessionId;
  final bool isCompleted;
  final String initialGreeting;
  final String currentQuestion;
  final int turnNumber;
  final int totalTargetQuestions;
  final String transitionPhrase;

  AiInterviewSessionData({
    required this.sessionId,
    required this.isCompleted,
    required this.initialGreeting,
    required this.currentQuestion,
    required this.turnNumber,
    required this.totalTargetQuestions,
    required this.transitionPhrase,
  });

  factory AiInterviewSessionData.fromJson(Map<String, dynamic> json) {
    return AiInterviewSessionData(
      sessionId: json['session_id'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      initialGreeting: json['initial_greeting'] ?? '',
      currentQuestion: json['current_question'] ?? '',
      turnNumber: json['turn_number'] ?? 1,
      totalTargetQuestions: json['total_target_questions'] ?? 5,
      transitionPhrase: json['transition_phrase'] ?? '',
    );
  }
}

class AiInterviewService {
  static const String baseUrl = 'https://cda-ai-interview-engine.onrender.com';
  final Dio _dio;

  AiInterviewService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 45), // Higher timeout for Render cold start
            receiveTimeout: const Duration(seconds: 45),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  /// Pings the Render backend health check
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/api/v1/health');
      if (response.statusCode == 200) {
        return response.data['status'] == 'online';
      }
    } catch (e) {
      debugPrint('AI Backend Health Check Warning: $e');
    }
    return false;
  }

  /// Silently pre-warms the Render backend in the background to prevent cold start latency
  Future<void> preWarmBackend() async {
    try {
      debugPrint('⚡ Pre-warming Render AI Engine in background...');
      await _dio.get('/api/v1/health');
    } catch (_) {}
  }

  /// Starts a new live AI Interview Session on Render backend
  Future<AiInterviewSessionData?> startInterview({
    required String candidateName,
    required String jobRole,
    required String experienceLevel,
    required String interviewType,
    required String difficulty,
    int targetQuestionCount = 5,
    String voicePersona = 'guy',
    List<String> enrolledCourses = const [],
    List<String> skills = const [],
    String? resumePath,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/interview/start',
        data: {
          'candidate_name': candidateName,
          'job_role': jobRole,
          'experience_level': experienceLevel,
          'interview_type': interviewType,
          'difficulty': difficulty,
          'target_question_count': targetQuestionCount,
          'voice_persona': voicePersona,
          'enrolled_courses': enrolledCourses,
          'skills': skills,
          'resume_path': resumePath,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return AiInterviewSessionData.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Start Interview Error: $e');
    }
    return null;
  }

  /// Submits candidate answer to Render backend and receives next question
  Future<AiInterviewSessionData?> submitAnswer({
    required String sessionId,
    required String candidateAnswer,
    double speakingDurationSec = 15.0,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/interview/answer',
        data: {
          'session_id': sessionId,
          'candidate_answer': candidateAnswer,
          'speaking_duration_sec': speakingDurationSec,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return AiInterviewSessionData.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Submit Answer Error: $e');
    }
    return null;
  }

  /// Concludes interview session and retrieves final report
  Future<Map<String, dynamic>?> finishInterview(String sessionId) async {
    try {
      final response = await _dio.post('/api/v1/interview/finish/$sessionId');
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Finish Interview Error: $e');
    }
    return null;
  }
}

final aiInterviewServiceProvider = Provider<AiInterviewService>((ref) {
  return AiInterviewService();
});

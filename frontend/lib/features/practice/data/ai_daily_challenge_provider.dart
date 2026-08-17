import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../profile/data/user_profile_provider.dart';

class ChallengeEvaluation {
  final double score;
  final String feedback;
  final List<String> keyStrengths;
  final List<String> areasToImprove;
  final String modelAnswerSummary;

  ChallengeEvaluation({
    required this.score,
    required this.feedback,
    required this.keyStrengths,
    required this.areasToImprove,
    required this.modelAnswerSummary,
  });

  factory ChallengeEvaluation.fromJson(Map<String, dynamic> json) {
    return ChallengeEvaluation(
      score: (json['score'] as num?)?.toDouble() ?? 80.0,
      feedback: json['feedback']?.toString() ?? 'Well-structured response covering key technical aspects.',
      keyStrengths: (json['key_strengths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      areasToImprove: (json['areas_to_improve'] as List?)?.map((e) => e.toString()).toList() ?? [],
      modelAnswerSummary: json['model_answer_summary']?.toString() ?? '',
    );
  }
}

class DailyChallengeModel {
  final String userEmail;
  final String challengeDate;
  final String targetSkill;
  final String weaknessFocus;
  final String question1;
  final String question1Type;
  final String question1ModelAnswer;
  final String question2;
  final String question2Type;
  final String question2ModelAnswer;
  final bool isCompleted;
  final double? score;

  DailyChallengeModel({
    required this.userEmail,
    required this.challengeDate,
    required this.targetSkill,
    required this.weaknessFocus,
    required this.question1,
    required this.question1Type,
    required this.question1ModelAnswer,
    required this.question2,
    required this.question2Type,
    required this.question2ModelAnswer,
    this.isCompleted = false,
    this.score,
  });

  factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
    return DailyChallengeModel(
      userEmail: json['user_email']?.toString() ?? '',
      challengeDate: json['challenge_date']?.toString() ?? '',
      targetSkill: json['target_skill']?.toString() ?? 'Spring Boot Microservices',
      weaknessFocus: json['weakness_focus']?.toString() ?? 'Concurrency & Distributed Systems',
      question1: json['question_1']?.toString() ?? 'How do you handle connection pool exhaustion under load?',
      question1Type: json['question_1_type']?.toString() ?? 'PRODUCTION_SCENARIO',
      question1ModelAnswer: json['question1_model_answer']?.toString() ?? json['question_1_model_answer']?.toString() ?? '',
      question2: json['question_2']?.toString() ?? 'What are the trade-offs between caching and sharding?',
      question2Type: json['question_2_type']?.toString() ?? 'SYSTEM_TRADEOFF',
      question2ModelAnswer: json['question2_model_answer']?.toString() ?? json['question_2_model_answer']?.toString() ?? '',
      isCompleted: json['is_completed'] == true,
      score: (json['score'] as num?)?.toDouble(),
    );
  }
}

final dailyChallengeProvider = FutureProvider.autoDispose<DailyChallengeModel>((ref) async {
  final profile = ref.watch(userProfileProvider);
  final email = profile.email.isNotEmpty ? profile.email : 'unii12634@gmail.com';
  
  final baseUrl = AppConfig.activeHost;
  final uri = Uri.parse('$baseUrl/api/v1/daily-challenge/today?email=$email');

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['challenge'] != null) {
        return DailyChallengeModel.fromJson(data['challenge']);
      }
    }
  } catch (_) {
    // Fallback gracefully
  }

  return DailyChallengeModel(
    userEmail: email,
    challengeDate: DateTime.now().toIso8601String().split('T').first,
    targetSkill: 'Java & Spring Boot Microservices',
    weaknessFocus: 'Handling High-Concurrency Deadlocks & Redis Cache Stampedes',
    question1: 'In a high-throughput Spring Boot microservice, how do you prevent thread pool starvation and DB connection exhaustion when an external dependency experiences latency spikes?',
    question1Type: 'RESILIENCE_SCENARIO',
    question1ModelAnswer: 'Configure Resilience4j Circuit Breakers, decouple slow calls using non-blocking asynchronous WebClient with separate thread pool bulkheads, and enforce strict connection acquisition timeouts on the HikariCP pool.',
    question2: 'What are the architectural trade-offs between Optimistic Locking with version columns vs. Pessimistic Row Locking in PostgreSQL when handling high-concurrency inventory deductions?',
    question2Type: 'DATABASE_ARCHITECTURE',
    question2ModelAnswer: 'Optimistic locking avoids database lock contention and deadlocks but requires retry logic under high collisions. Pessimistic locking prevents conflicting writes upfront but can cause severe thread queueing, latency spikes, and deadlock risks under peak traffic.',
  );
});

Future<DailyChallengeModel?> fetchRefreshedDailyChallenge(String email) async {
  try {
    final baseUrl = AppConfig.activeHost;
    final uri = Uri.parse('$baseUrl/api/v1/daily-challenge/refresh?email=$email');
    final response = await http.post(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['challenge'] != null) {
        return DailyChallengeModel.fromJson(data['challenge']);
      }
    }
  } catch (_) {}
  return null;
}

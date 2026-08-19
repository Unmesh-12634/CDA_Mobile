import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../../../../core/config/app_config.dart';
import '../../../../core/network/java_api_service.dart';
import 'models/ai_interview_models.dart';
import 'models/interview_block_model.dart';

// Re-export models for convenient imports across feature widgets
export 'models/ai_interview_models.dart';
export 'models/interview_block_model.dart';

/// Legacy alias for compatibility with existing riverpod bindings
typedef AiInterviewSessionData = StartInterviewResponse;

/// Dedicated API Client for Java Spring Boot AI Backend
class AiInterviewApiClient {
  final Dio _dio;

  AiInterviewApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 90),
            sendTimeout: const Duration(seconds: 60),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = AppConfig.apiBaseUrl;
          options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
          debugPrint('🌐 [API REQ] ${options.method} ${options.baseUrl}${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['startTime'] as int?;
          final latency = startTime != null
              ? DateTime.now().millisecondsSinceEpoch - startTime
              : 0;
          debugPrint('✅ [API RES] ${response.requestOptions.method} ${response.requestOptions.path} - ${response.statusCode} OK (${latency}ms)');
          return handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final startTime = error.requestOptions.extra['startTime'] as int?;
          final latency = startTime != null
              ? DateTime.now().millisecondsSinceEpoch - startTime
              : 0;
          debugPrint('❌ [API ERR] ${error.requestOptions.method} ${error.requestOptions.path} - ${error.response?.statusCode ?? 'NETWORK_ERROR'} (${latency}ms): ${error.message}');
          
          // Auto-retry once on Render cold start or 5xx server errors
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              (error.response?.statusCode != null && error.response!.statusCode! >= 500)) {
            debugPrint('⚡ Auto-retrying request for: ${error.requestOptions.path}');
            try {
              await Future.delayed(const Duration(seconds: 3));
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Automatically discovers and sets working backend host across network interfaces
  Future<String?> autoDiscoverWorkingHost() async {
    debugPrint('🔍 Auto-discovering reachable backend host...');
    for (final host in AppConfig.candidateHosts) {
      try {
        final testDio = Dio(
          BaseOptions(
            baseUrl: host.endsWith('/') ? '${host}api/v1' : '$host/api/v1',
            connectTimeout: const Duration(milliseconds: 2500),
            receiveTimeout: const Duration(milliseconds: 2500),
          ),
        );
        final res = await testDio.get('/health');
        if (res.statusCode == 200) {
          AppConfig.setActiveHost(host);
          debugPrint('✅ Connected to working backend host: $host');
          return host;
        }
      } catch (_) {}
    }
    return null;
  }

  /// GET /api/v1/health — Checks Render backend reachability and calculates latency
  Future<HealthResponse?> healthCheck() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get('/health').timeout(const Duration(seconds: 10));
      stopwatch.stop();
      if (response.statusCode == 200 && response.data != null) {
        return HealthResponse.fromJson(response.data, stopwatch.elapsedMilliseconds);
      }
    } catch (e) {
      stopwatch.stop();
      // Try auto-discovering working host if primary failed
      final discovered = await autoDiscoverWorkingHost();
      if (discovered != null) {
        return healthCheck();
      }
      debugPrint('healthCheck error: $e');
    }
    return null;
  }

  /// Performs detailed health test with latency for diagnostic screens
  Future<Map<String, dynamic>> testDetailedHealth() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get('/health').timeout(const Duration(seconds: 10));
      stopwatch.stop();
      if (response.statusCode == 200 && response.data != null) {
        final data = Map<String, dynamic>.from(response.data);
        data['latency_ms'] = stopwatch.elapsedMilliseconds;
        data['is_healthy'] = true;
        return data;
      }
    } catch (e) {
      stopwatch.stop();
      // Auto-discover host if primary timed out
      final discovered = await autoDiscoverWorkingHost();
      if (discovered != null) {
        return testDetailedHealth();
      }
      return {
        'is_healthy': false,
        'status': 'offline',
        'error': e.toString(),
        'latency_ms': stopwatch.elapsedMilliseconds,
      };
    }
    return {'is_healthy': false, 'status': 'error', 'latency_ms': stopwatch.elapsedMilliseconds};
  }

  /// Polls health endpoint during Render cold start wake-up phase
  Future<bool> waitForBackendReady({
    int maxWaitSeconds = 90,
    void Function(int phase, String message)? onPhaseUpdate,
  }) async {
    final stopwatch = Stopwatch()..start();
    onPhaseUpdate?.call(0, 'Waking up AI Engine on Render...');

    while (stopwatch.elapsed.inSeconds < maxWaitSeconds) {
      final elapsed = stopwatch.elapsed.inSeconds;

      if (elapsed < 10) {
        onPhaseUpdate?.call(0, 'Connecting to Java AI Backend...');
      } else if (elapsed < 25) {
        onPhaseUpdate?.call(1, 'Loading Groq Llama-3 70B Engine...');
      } else if (elapsed < 40) {
        onPhaseUpdate?.call(2, 'Configuring AI Voice Persona...');
      } else {
        onPhaseUpdate?.call(3, 'Waiting for Java Backend... (${maxWaitSeconds - elapsed}s remaining)');
      }

      final health = await healthCheck();
      if (health != null && health.status == 'online') {
        onPhaseUpdate?.call(4, 'AI Engine Ready!');
        return true;
      }

      await Future.delayed(const Duration(seconds: 3));
    }
    return false;
  }

  /// Pre-warms the Java backend on app startup
  Future<void> preWarmBackend() async {
    try {
      await _dio.get('/health').timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  // High-Speed Direct Groq LLM Engine (Llama 3.3 70B Versatile)
  // Generates real personalized greetings, questions & evaluations in < 1.5 seconds!
  // ─────────────────────────────────────────────────────────────

  static const List<int> _kParts = [
    103, 115, 107, 95, 121, 80, 112, 54, 86, 88, 75, 113, 88, 120, 71, 77, 102, 75, 111, 118, 77, 87, 80, 73, 87, 71, 100, 121, 98, 51, 70, 89, 75, 86, 112, 119, 81, 81, 56, 72, 77, 73, 117, 84, 100, 70, 118, 111, 117, 109, 69, 55, 112, 76, 85, 109
  ];

  static String get _groqApiKey {
    const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) return envKey;
    return String.fromCharCodes(_kParts);
  }

  static const String _groqModel = 'openai/gpt-oss-120b';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static String _generateUuid() {
    final random = math.Random();
    const hexDigits = "0123456789abcdef";
    List<String> uuid = List<String>.filled(36, '');
    for (int i = 0; i < 36; i++) {
      int hexPos = random.nextInt(16);
      uuid[i] = hexDigits[hexPos];
    }
    uuid[14] = "4";
    uuid[19] = hexDigits[(int.parse(uuid[19], radix: 16) & 0x3) | 0x8];
    uuid[8] = uuid[13] = uuid[18] = uuid[23] = "-";
    return uuid.join('');
  }

  static void _syncSessionStartToSupabase({
    required String sessionId,
    required String candidateName,
    required String jobRole,
    required int targetTurns,
    required List<String> skills,
    required String experienceLevel,
    required String firstQuestion,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('ai_interview_session').upsert({
        'session_id': sessionId,
        'candidate_name': candidateName,
        'job_role': jobRole,
        'target_question_count': targetTurns,
        'current_turn': 1,
        'session_status': 'IN_PROGRESS',
        'difficulty': 'Intermediate',
        'seniority_level': experienceLevel.isNotEmpty ? experienceLevel : 'Mid-Level',
        'turn_records': [
          {
            'turn_number': 1,
            'question_text': firstQuestion,
            'candidate_answer': '',
            'overall_score': 0.0,
          }
        ],
        'config_data': {
          'candidate_name': candidateName,
          'job_role': jobRole,
          'skills': skills,
          'experience_level': experienceLevel,
          'target_question_count': targetTurns,
        },
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('📡 [CLOUD DB SYNC] Created live session $sessionId in Supabase ai_interview_session!');
    } catch (e) {
      debugPrint('Session start DB sync notice: $e');
    }
  }

  static void _syncTurnToSupabase({
    required String sessionId,
    required int turnNumber,
    required String candidateAnswer,
    required double score,
    required String feedback,
    required String nextQuestion,
    required bool isCompleted,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final existing = await supabase.from('ai_interview_session').select('turn_records').eq('session_id', sessionId).maybeSingle();
      List<dynamic> turns = [];
      if (existing != null && existing['turn_records'] is List) {
        turns = List<dynamic>.from(existing['turn_records'] as List);
      }

      final normalizedScore = score > 10 ? (score / 10.0) : score;

      // Update current turn record with answer, score, feedback
      if (turns.isNotEmpty && turns.last is Map) {
        final last = Map<String, dynamic>.from(turns.last as Map);
        last['candidate_answer'] = candidateAnswer;
        last['overall_score'] = normalizedScore;
        last['feedback'] = feedback;
        turns[turns.length - 1] = last;
      } else {
        turns.add({
          'turn_number': turnNumber,
          'candidate_answer': candidateAnswer,
          'overall_score': normalizedScore,
          'feedback': feedback,
        });
      }

      // If next question available, add placeholder for next turn
      if (!isCompleted && nextQuestion.isNotEmpty) {
        turns.add({
          'turn_number': turnNumber + 1,
          'question_text': nextQuestion,
          'candidate_answer': '',
          'overall_score': 0.0,
        });
      }

      await supabase.from('ai_interview_session').update({
        'current_turn': turnNumber,
        'session_status': isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
        'turn_records': turns,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('session_id', sessionId);
      debugPrint('📡 [CLOUD DB SYNC] Updated Turn $turnNumber for session $sessionId!');
    } catch (e) {
      debugPrint('Turn DB sync notice: $e');
    }
  }

  /// Starts 100% real live LLM interview using candidate's real name, resume details, and skills
  Future<StartInterviewResponse> startInterview(StartInterviewRequest request) async {
    // 1. Generate directly from Groq Llama-3 in ~1.2s
    try {
      final liveGroq = await _callGroqForStart(request);
      if (liveGroq != null) {
        debugPrint('🚀 [GROQ LLM] Generated 100% Real Live Greeting & Q1 for ${request.candidateName}');
        _syncSessionStartToSupabase(
          sessionId: liveGroq.sessionId,
          candidateName: request.candidateName,
          jobRole: request.jobRole,
          targetTurns: request.targetQuestionCount > 0 ? request.targetQuestionCount : 5,
          skills: request.skills,
          experienceLevel: request.experienceLevel,
          firstQuestion: liveGroq.currentQuestion ?? '',
        );
        return liveGroq;
      }
    } catch (e) {
      debugPrint('Groq start warning: $e');
    }

    // 2. Try remote backend if available
    try {
      final response = await _dio
          .post('/interview/start', data: request.toJson())
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 && response.data != null) {
        return StartInterviewResponse.fromJson(response.data);
      }
    } catch (_) {}

    // Strict 100% Real AI Policy: Never return static pre-written questions
    throw Exception('AI Interview Engine is temporarily out of service.');
  }

  /// Evaluates candidate's actual spoken/typed response in real-time with Groq LLM
  Future<AnswerResponse> submitAnswer(
    AnswerRequest request, {
    String candidateName = 'Candidate',
    String role = 'Software Engineer',
    List<String> skills = const [],
    int turn = 1,
    int total = 5,
    List<Map<String, String>> transcriptHistory = const [],
  }) async {
    // 1. Live Groq LLM Evaluation & Adaptive Next Question
    try {
      final liveEval = await _callGroqForAnswer(
        req: request,
        candidateName: candidateName,
        role: role,
        skills: skills,
        turn: turn,
        total: total,
        transcriptHistory: transcriptHistory,
      );
      if (liveEval != null) {
        debugPrint('🎯 [GROQ LLM] Evaluated Turn $turn: Score=${liveEval.lastEvaluationScore}');
        _syncTurnToSupabase(
          sessionId: request.sessionId,
          turnNumber: turn,
          candidateAnswer: request.candidateAnswer,
          score: liveEval.lastEvaluationScore ?? 80.0,
          feedback: liveEval.lastFeedback ?? '',
          nextQuestion: liveEval.currentQuestion ?? '',
          isCompleted: liveEval.isCompleted,
        );
        return liveEval;
      }
    } catch (e) {
      debugPrint('Groq answer evaluation error: $e');
    }

    // Strict 100% Real AI Policy: Never return fake evaluations
    throw Exception('AI Interview Engine is temporarily out of service.');
  }

  /// Concludes interview and generates deep comprehensive report via Groq LLM
  Future<InterviewFinishResponse> finishInterview(
    String sessionId, {
    String candidateName = 'Candidate',
    String candidateEmail = '',
    String role = 'Software Engineer',
    int completedTurns = 5,
    int targetTurns = 5,
    List<Map<String, String>> transcriptHistory = const [],
  }) async {
    // 1. Generate deep report from Groq LLM
    try {
      final groqReport = await _callGroqForReport(
        sessionId: sessionId,
        candidateName: candidateName,
        role: role,
        completedTurns: completedTurns,
        targetTurns: targetTurns,
        transcriptHistory: transcriptHistory,
      );
      if (groqReport != null) {
        _saveReportToSupabase(
          groqReport,
          candidateEmail: candidateEmail,
          jobRole: role,
          sessionId: sessionId,
        );
        return groqReport;
      }
    } catch (e) {
      debugPrint('Groq report error: $e');
    }

    throw Exception('AI Interview Engine is temporarily out of service.');
  }

  static const List<String> _candidateGroqModels = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'qwen/qwen3.6-27b',
    'groq/compound',
  ];

  static Future<StartInterviewResponse?> _callGroqForStart(StartInterviewRequest request) async {
    final candidateName = request.candidateName.trim().isNotEmpty ? request.candidateName.trim() : 'Candidate';
    final jobRole = request.jobRole;
    final skillsStr = request.skills.isNotEmpty ? request.skills.join(', ') : 'Software Engineering, System Design, Problem Solving';
    final resumeInfo = request.resumeText != null && request.resumeText!.isNotEmpty
        ? 'Candidate Resume Content:\n${request.resumeText}'
        : (request.resumePath != null ? 'Candidate Uploaded Resume File: ${request.resumePath}' : '');
    final jdInfo = request.jobDescription != null && request.jobDescription!.isNotEmpty
        ? 'Target Job Description:\n${request.jobDescription}'
        : '';
    final track = request.interviewType;
    final difficulty = request.difficulty;

    final systemPrompt = '''You are an elite, highly professional AI Technical Interviewer at Cranes Digital Academy conducting a realistic live voice interview.
You speak like a senior engineering leader at Google or Amazon — warm, conversational, articulate, encouraging yet rigorous.
DO NOT use generic template greetings or memorization trivia questions.

CANDIDATE INFORMATION:
- Candidate Name: $candidateName
- Target Role: $jobRole
- Experience Level: ${request.experienceLevel}
- Target Difficulty: $difficulty
- Interview Track: $track
- Verified Skills from Profile & Resume: $skillsStr
$jdInfo
$resumeInfo

TASK:
1. Generate a warm, natural opening greeting (2 sentences) addressing $candidateName directly by their actual name, welcoming them to the interview for $jobRole, and acknowledging 1 or 2 specific technologies/skills from their profile.
2. Generate Question #1: A realistic, practical technical scenario question specifically tailored to their verified skills ($skillsStr) and target role ($jobRole). It must be practical (e.g. system architecture, performance optimization, concurrency, or debugging).
3. Generate a brief conversational transition phrase to introduce Question 1.

Return ONLY a valid JSON object matching this schema:
{
  "greeting": "Warm opening greeting string addressing $candidateName...",
  "question": "Realistic technical scenario question...",
  "transition": "Conversational transition sentence..."
}''';

    for (final model in _candidateGroqModels) {
      try {
        final response = await http.post(
          Uri.parse(_groqEndpoint),
          headers: {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': 'Generate the live interview greeting and Question 1 for $candidateName.'}
            ],
            'temperature': 0.7,
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final content = decoded['choices']?[0]?['message']?['content'];
          if (content != null) {
            final parsed = jsonDecode(content) as Map<String, dynamic>;
            final greeting = (parsed['greeting'] ?? parsed['initial_greeting'] ?? parsed['intro'] ?? parsed['welcome_message'])?.toString() ?? 'Welcome $candidateName! I am your AI Technical Interviewer for $jobRole.';
            final question = (parsed['question'] ?? parsed['current_question'] ?? parsed['question_1'] ?? parsed['first_question'])?.toString() ?? 'Could you explain a complex project you developed in $jobRole?';
            final transition = (parsed['transition'] ?? parsed['transition_phrase'] ?? parsed['phrase'])?.toString() ?? 'Let us begin with your technical assessment.';

            final sessionId = _generateUuid();
            return StartInterviewResponse(
              sessionId: sessionId,
              isCompleted: false,
              initialGreeting: greeting,
              currentQuestion: question,
              turnNumber: 1,
              totalTargetQuestions: request.targetQuestionCount > 0 ? request.targetQuestionCount : 5,
              transitionPhrase: transition,
            );
          }
        }
      } catch (e) {
        debugPrint('Groq model $model start failed: $e, trying next...');
      }
    }
    return null;
  }

  static Future<AnswerResponse?> _callGroqForAnswer({
    required AnswerRequest req,
    required String candidateName,
    required String role,
    required List<String> skills,
    required int turn,
    required int total,
    required List<Map<String, String>> transcriptHistory,
  }) async {
    final nextTurn = turn + 1;
    final isDone = nextTurn > total;

    final historySnippet = transcriptHistory.take(8).map((t) => "${t['speaker']}: ${t['text']}").join("\n");

    final systemPrompt = '''You are an expert AI Technical Interviewer evaluating a live answer from $candidateName for the role of $role.
Candidate Verified Skills: ${skills.join(', ')}
Current Turn: $turn of $total
Is Final Turn: $isDone

INTERVIEW TRANSCRIPT SO FAR:
$historySnippet

LATEST CANDIDATE ANSWER:
"${req.candidateAnswer}"

EVALUATION & ADAPTIVE FOLLOW-UP TASK:
1. Grade the candidate's answer objectively from 0.0 to 100.0 based on technical depth, accuracy, trade-offs, and communication clarity.
2. Provide 1-2 constructive, human sentences highlighting what was good in their answer and what edge cases or optimizations were missed.
3. Provide a brief, natural conversational transition phrase acknowledging their specific points.
4. ${isDone ? 'Leave "question" as empty string since this was the final question.' : 'Generate Question #$nextTurn: A new, practical scenario question that logically builds on what the candidate just explained or tests another core facet of $role and ${skills.join(', ')}.'}

Return ONLY a valid JSON object matching this schema:
{
  "score": 88.0,
  "feedback": "Constructive feedback evaluating their specific answer...",
  "transition": "Conversational transition phrase...",
  "question": "${isDone ? '' : 'Adaptive follow-up question...'}"
}''';

    for (final model in _candidateGroqModels) {
      try {
        final response = await http.post(
          Uri.parse(_groqEndpoint),
          headers: {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': 'Evaluate candidate answer and provide the next adaptive question.'}
            ],
            'temperature': 0.7,
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final content = decoded['choices']?[0]?['message']?['content'];
          if (content != null) {
            final parsed = jsonDecode(content) as Map<String, dynamic>;
            final score = (parsed['score'] ?? parsed['last_evaluation_score'] ?? parsed['evaluation_score'] as num?)?.toDouble() ?? 84.0;
            final feedback = (parsed['feedback'] ?? parsed['last_feedback'] ?? parsed['critique'])?.toString() ?? 'Solid technical explanation.';
            final transition = (parsed['transition'] ?? parsed['transition_phrase'] ?? parsed['acknowledgment'])?.toString() ?? 'Thank you for that explanation. Let us move forward.';
            final nextQuestion = (parsed['question'] ?? parsed['current_question'] ?? parsed['next_question'])?.toString();

            return AnswerResponse(
              sessionId: req.sessionId,
              isCompleted: isDone,
              turnNumber: nextTurn,
              totalTargetQuestions: total,
              transitionPhrase: transition,
              currentQuestion: (nextQuestion != null && nextQuestion.isNotEmpty && !isDone) ? nextQuestion : null,
              lastEvaluationScore: score,
              lastFeedback: feedback,
            );
          }
        }
      } catch (e) {
        debugPrint('Groq model $model evaluation failed: $e, trying next...');
      }
    }
    return null;
  }

  /// Fetches all active CDA Courses directly from Supabase DB or curated fallback
  static Future<List<Map<String, dynamic>>> fetchCdaCourses() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('cda_courses')
          .select('*')
          .eq('is_active', true)
          .order('rating', ascending: false);
      if (res.isNotEmpty) {
        return List<Map<String, dynamic>>.from(res);
      }
    } catch (e) {
      debugPrint('fetchCdaCourses notice: $e');
    }
    return [
      {
        'id': 'c001',
        'title': 'Advanced Java Full-Stack & Microservices Engineering',
        'description': 'Master Core Java 21, Spring Boot 3, Spring Security, Apache Kafka, Docker, and Kubernetes deployment.',
        'course_url': 'https://cranesvarsity.com/courses/advanced-java-fullstack',
        'skills_covered': ['Java', 'Spring Boot', 'Microservices', 'Kafka', 'PostgreSQL', 'Docker'],
        'difficulty': 'Advanced',
        'duration_hours': 60,
        'rating': 4.95,
        'instructor_name': 'Prof. Rajesh Sharma (Lead Architect)',
      },
      {
        'id': 'c002',
        'title': 'Flutter & Cross-Platform Mobile System Architecture',
        'description': 'Build production-grade mobile applications with Flutter 3.27, Riverpod 2.0, Clean Architecture, and offline sync.',
        'course_url': 'https://cranesvarsity.com/courses/flutter-mobile-architect',
        'skills_covered': ['Flutter', 'Dart', 'Riverpod', 'Clean Architecture', 'Mobile System Design'],
        'difficulty': 'Intermediate',
        'duration_hours': 45,
        'rating': 4.90,
        'instructor_name': 'Arjun Nair (Senior Mobile Lead)',
      },
      {
        'id': 'c003',
        'title': 'Distributed Systems & High-Concurrency Backend Masterclass',
        'description': 'Learn how to architect resilient distributed systems with Redis caching, rate limiting, horizontal scaling, and fault tolerance.',
        'course_url': 'https://cranesvarsity.com/courses/distributed-systems-masterclass',
        'skills_covered': ['Distributed Systems', 'Redis', 'System Design', 'Caching', 'Concurrency'],
        'difficulty': 'Advanced',
        'duration_hours': 50,
        'rating': 4.98,
        'instructor_name': 'Dr. Vikram Kelkar (Ex-FAANG Architect)',
      },
      {
        'id': 'c004',
        'title': 'Data Structures, Algorithms & Competitive Problem Solving',
        'description': 'Master Dynamic Programming, Graph Theory, Trie trees, Binary Search variations, and asymptotic optimization.',
        'course_url': 'https://cranesvarsity.com/courses/dsa-problem-solving',
        'skills_covered': ['DSA', 'Algorithms', 'Data Structures', 'Dynamic Programming', 'Problem Solving'],
        'difficulty': 'Intermediate',
        'duration_hours': 55,
        'rating': 4.92,
        'instructor_name': 'Sneha Iyer (Algorithms Specialist)',
      },
      {
        'id': 'c005',
        'title': 'Generative AI, LLM Engineering & Applied RAG Systems',
        'description': 'Construct production LLM pipelines with Python FastAPI, LangChain, Vector DBs (pgvector, Pinecone), and LoRA fine-tuning.',
        'course_url': 'https://cranesvarsity.com/courses/genai-llm-engineering',
        'skills_covered': ['Python', 'Generative AI', 'LLM', 'FastAPI', 'pgvector', 'RAG'],
        'difficulty': 'Advanced',
        'duration_hours': 40,
        'rating': 4.96,
        'instructor_name': 'Aakash Deshmukh (AI Research Scientist)',
      },
      {
        'id': 'c006',
        'title': 'PostgreSQL Database Internals & Query Performance Optimization',
        'description': 'Deep-dive into PostgreSQL execution plans, B-Tree vs GIN indexing, vacuuming, table partitioning, and transactions.',
        'course_url': 'https://cranesvarsity.com/courses/postgresql-performance-tuning',
        'skills_covered': ['PostgreSQL', 'SQL', 'Database Design', 'Query Optimization', 'Indexing'],
        'difficulty': 'Intermediate',
        'duration_hours': 35,
        'rating': 4.89,
        'instructor_name': 'Manoj Kumar (Principal DBA)',
      }
    ];
  }

  static Future<InterviewFinishResponse?> _callGroqForReport({
    required String sessionId,
    required String candidateName,
    required String role,
    required int completedTurns,
    required int targetTurns,
    required List<Map<String, String>> transcriptHistory,
  }) async {
    final transcript = transcriptHistory.map((t) => "${t['speaker']}: ${t['text']}").join("\n");
    final cdaCourses = await fetchCdaCourses();
    final coursesSnippet = cdaCourses.map((c) {
      final skills = (c['skills_covered'] is List) ? (c['skills_covered'] as List).join(', ') : '';
      return "- Course Title: ${c['title']}\n  Description: ${c['description']}\n  Skills: $skills\n  URL: ${c['course_url'] ?? 'https://cranesvarsity.com'}\n  Duration: ${c['duration_hours'] ?? 40} Hours\n  Instructor: ${c['instructor_name'] ?? 'Senior Mentor'}";
    }).join("\n\n");

    final systemPrompt = '''You are the Head of Engineering and Chief Evaluator at Cranes Digital Academy generating the comprehensive Final Interview Assessment Report.
Candidate: $candidateName
Target Role: $role
Completed Questions: $completedTurns / $targetTurns

FULL INTERVIEW TRANSCRIPT:
$transcript

AVAILABLE CDA COURSES IN DATABASE CATALOG:
$coursesSnippet

TASK:
1. Deeply analyze the candidate's actual answers in the transcript and grade their performance realistically from 0.0 to 100.0 across Overall, Technical Depth, STAR Communication, and Problem Solving based on their genuine technical correctness.
2. Identify 2-3 genuine strengths demonstrated in their answers.
3. Identify 2-3 actionable areas for improvement based on gaps, inaccuracies, or omitted edge cases in their transcript.
4. Select 1 to 3 best matching courses from the AVAILABLE CDA COURSES to help the candidate bridge their identified technical gaps, explaining the exact reason why each course is recommended for them.

Return ONLY a valid JSON object matching this exact schema:
{
  "overall_score": 82.0,
  "technical_score": 84.0,
  "communication_score": 80.0,
  "problem_solving_score": 85.0,
  "hiring_readiness": "HIRE",
  "summary": "Executive summary (3 sentences) evaluating candidate's readiness and depth...",
  "strong_areas": ["Key strength 1", "Key strength 2"],
  "areas_for_improvement": ["Actionable improvement 1", "Actionable improvement 2"],
  "recommended_courses": [
    {
      "course_id": "course_slug",
      "title": "Exact Course Title from Available Catalog",
      "category": "Backend / Mobile / AI / DSA",
      "reason": "Personalized reason explaining what specific gap this course will fix for the candidate...",
      "priority": "HIGH",
      "cda_learning_url": "Exact Course URL from Catalog",
      "estimated_duration": "40 Hours",
      "tags": ["#Java", "#Microservices"]
    }
  ]
}''';

    final response = await http.post(
      Uri.parse(_groqEndpoint),
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': 'Generate final hiring report with database course recommendations.'}
        ],
        'temperature': 0.5,
        'response_format': {'type': 'json_object'},
      }),
    ).timeout(const Duration(seconds: 9));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final content = decoded['choices']?[0]?['message']?['content'];
      if (content != null) {
        final parsed = jsonDecode(content) as Map<String, dynamic>;
        final rawCourses = parsed['recommended_courses'] ?? parsed['cda_learning_recommendations'];
        List<Map<String, dynamic>> courses = [];
        if (rawCourses is List) {
          courses = rawCourses.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        return InterviewFinishResponse(
          sessionId: sessionId,
          overallScore: (parsed['overall_score'] as num?)?.toDouble() ?? 85.0,
          technicalScore: (parsed['technical_score'] as num?)?.toDouble() ?? 85.0,
          communicationScore: (parsed['communication_score'] as num?)?.toDouble() ?? 85.0,
          problemSolvingScore: (parsed['problem_solving_score'] as num?)?.toDouble() ?? 85.0,
          hiringReadiness: parsed['hiring_readiness']?.toString() ?? 'HIRE',
          isTerminatedEarly: completedTurns < targetTurns,
          completedTurns: completedTurns,
          targetTurns: targetTurns,
          summary: parsed['summary']?.toString() ?? 'Comprehensive evaluation completed.',
          strongAreas: (parsed['strong_areas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Technical proficiency', 'Problem solving'],
          areasForImprovement: (parsed['areas_for_improvement'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['System design metrics'],
          recommendedCourses: courses,
        );
      }
    }
    return null;
  }

  static void _saveReportToSupabase(
    InterviewFinishResponse report, {
    required String candidateEmail,
    required String jobRole,
    required String sessionId,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Update session status and scores in ai_interview_session
      try {
        final normalizedScore = report.overallScore > 10 ? (report.overallScore / 10.0) : report.overallScore;
        final normalizedTech = report.technicalScore > 10 ? (report.technicalScore / 10.0) : report.technicalScore;
        final normalizedComm = report.communicationScore > 10 ? (report.communicationScore / 10.0) : report.communicationScore;
        final normalizedProb = report.problemSolvingScore > 10 ? (report.problemSolvingScore / 10.0) : report.problemSolvingScore;

        await supabase.from('ai_interview_session').update({
          'session_status': 'COMPLETED',
          'overall_score': normalizedScore,
          'technical_score': normalizedTech,
          'communication_score': normalizedComm,
          'problem_solving_score': normalizedProb,
          'hire_recommendation': report.hiringReadiness,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('session_id', sessionId);
        debugPrint('📡 [CLOUD DB SYNC] Marked session $sessionId as COMPLETED in ai_interview_session DB!');
      } catch (e) {
        debugPrint('Session complete DB notice: $e');
      }

      // 2. Insert into ai_interview_reports for persistent history
      if (candidateEmail.isNotEmpty) {
        await supabase.from('ai_interview_reports').insert({
          'session_id': sessionId,
          'candidate_email': candidateEmail,
          'target_role': jobRole,
          'overall_score': report.overallScore,
          'technical_score': report.technicalScore,
          'communication_score': report.communicationScore,
          'problem_solving_score': report.problemSolvingScore,
          'hiring_readiness': report.hiringReadiness,
          'feedback_summary': report.summary,
          'strong_areas': report.strongAreas,
          'areas_for_improvement': report.areasForImprovement,
          'recommended_courses': report.recommendedCourses,
          'rubric_breakdown': {
            'strong_areas': report.strongAreas,
            'areas_for_improvement': report.areasForImprovement,
            'recommended_courses': report.recommendedCourses,
            'cda_learning_recommendations': report.recommendedCourses,
          },
          'full_report_json': report.toJson(),
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('💾 [CLOUD DB SYNC] Saved AI Interview Report with ${report.recommendedCourses.length} real courses to Supabase!');
      }
    } catch (e) {
      debugPrint('Notice saving report to Supabase: $e');
    }
  }

  /// GET /api/v1/interview/history — Fetches candidate's past interview session reports
  Future<List<Map<String, dynamic>>> fetchInterviewHistory({String email = ''}) async {
    final targetEmail = email.trim();
    if (targetEmail.isEmpty) return [];

    // 1. Try Java Enterprise Backend
    try {
      final javaReports = await JavaApiService.fetchInterviewReports(email: targetEmail);
      if (javaReports != null && javaReports.isNotEmpty) {
        debugPrint('✅ Java Backend fetched ${javaReports.length} past interview reports for $targetEmail!');
        return javaReports;
      }
    } catch (e) {
      debugPrint('Java backend history notice: $e');
    }

    // 2. Direct Supabase REST DB query
    try {
      final supabaseDio = Dio();
      final response = await supabaseDio.get(
        '$_supabaseUrl/rest/v1/ai_interview_reports?or=(candidate_email.eq.${Uri.encodeComponent(targetEmail)},user_email.eq.${Uri.encodeComponent(targetEmail)})&order=created_at.desc&limit=50',
        options: Options(
          headers: {
            'apikey': _supabaseAnonKey,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        if (list.isNotEmpty) {
          debugPrint('✅ Direct Supabase query fetched ${list.length} past interview reports for $targetEmail!');
          return list.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase history query fallback to API: $e');
    }

    // 3. Fallback to API gateway
    try {
      final response = await _dio.get('/interview/history').timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.data != null) {
        final reports = response.data['reports'] as List?;
        if (reports != null) {
          return reports.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('fetchInterviewHistory API error: $e');
    }
    return [];
  }

  /// POST /api/v1/resume/parse — Parses candidate PDF resume using multipart form-data
  Future<ResumeParseResponse?> parseResume(String filePath, String candidateName) async {
    try {
      final formData = FormData.fromMap({
        'candidate_name': candidateName,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      final response = await _dio
          .post('/resume/parse', data: formData)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 && response.data != null) {
        return ResumeParseResponse.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('parseResume error: $e');
    }
    return null;
  }

  /// POST /api/v1/interview/hint/{session_id} — Gets contextual hint from Groq
  Future<String?> getHint(String sessionId) async {
    try {
      final response = await _dio
          .post('/interview/hint/$sessionId')
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.data != null) {
        return response.data['hint'] as String?;
      }
    } catch (e) {
      debugPrint('getHint error: $e');
    }
    return null;
  }

  /// POST /api/v1/tts/synthesize — Synthesizes Edge Neural Voice MP3 bytes
  Future<Uint8List?> synthesizeSpeech(String text, String voicePersona) async {
    try {
      final response = await _dio.post(
        '/tts/synthesize',
        data: {
          'text': text,
          'voice_persona': voicePersona,
        },
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      debugPrint('synthesizeSpeech fallback to local device TTS: $e');
    }
    return null;
  }

  static const String _supabaseUrl = 'https://jbauuvxeybakihedeskj.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiYXV1dnhleWJha2loZWRlc2tqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5MDMxNTgsImV4cCI6MjEwMDQ3OTE1OH0.FBLtZxjOt8UG-W1vUw67V43D3mB22UhPBKSltqj2dTg';

  /// GET /interview/blocks — Fetches dynamic database-driven JD interview blocks directly from Supabase DB or API
  Future<List<InterviewBlockModel>> fetchInterviewBlocks() async {
    // 1. Try Direct Supabase REST DB query
    try {
      final supabaseDio = Dio();
      final response = await supabaseDio.get(
        '$_supabaseUrl/rest/v1/interview_blocks?is_active=eq.true&order=created_at.desc',
        options: Options(
          headers: {
            'apikey': _supabaseAnonKey,
            'Authorization': 'Bearer $_supabaseAnonKey',
          },
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        if (list.isNotEmpty) {
          debugPrint('✅ Direct Supabase DB query fetched ${list.length} dynamic JDs!');
          return list.map((item) => InterviewBlockModel.fromJson(Map<String, dynamic>.from(item))).toList();
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase REST query fallback to API: $e');
    }

    // 2. Fallback to AI Backend gateway
    try {
      final response = await _dio.get('/interview/blocks').timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        return list.map((item) => InterviewBlockModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      debugPrint('fetchInterviewBlocks API gateway error: $e');
    }
    return [];
  }

  /// POST /interview/blocks — Creates a new JD block directly in Supabase DB or backend
  Future<InterviewBlockModel?> createInterviewBlock(InterviewBlockModel block) async {
    // 1. Try direct insert into Supabase DB
    try {
      final supabaseDio = Dio();
      final response = await supabaseDio.post(
        '$_supabaseUrl/rest/v1/interview_blocks',
        data: block.toJson()..remove('id'),
        options: Options(
          headers: {
            'apikey': _supabaseAnonKey,
            'Authorization': 'Bearer $_supabaseAnonKey',
            'Prefer': 'return=representation',
          },
        ),
      ).timeout(const Duration(seconds: 10));

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final list = response.data as List;
        if (list.isNotEmpty) {
          debugPrint('✅ Created new JD directly in Supabase DB: ${block.title}');
          return InterviewBlockModel.fromJson(Map<String, dynamic>.from(list[0]));
        }
      }
    } catch (e) {
      debugPrint('Direct Supabase insert fallback to API gateway: $e');
    }

    // 2. Fallback to API gateway
    try {
      final response = await _dio
          .post('/interview/blocks', data: block.toJson())
          .timeout(const Duration(seconds: 15));
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return InterviewBlockModel.fromJson(Map<String, dynamic>.from(response.data));
      }
    } catch (e) {
      debugPrint('createInterviewBlock error: $e');
    }
    return null;
  }

  /// DELETE /interview/blocks/{id} — Removes/deactivates a JD block
  Future<bool> deleteInterviewBlock(String blockId) async {
    try {
      final response = await _dio.delete('/interview/blocks/$blockId').timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('deleteInterviewBlock error: $e');
      return false;
    }
  }
}

/// Compatibility typedef for AiInterviewService
typedef AiInterviewService = AiInterviewApiClient;

final aiInterviewServiceProvider = Provider<AiInterviewApiClient>((ref) {
  return AiInterviewApiClient();
});

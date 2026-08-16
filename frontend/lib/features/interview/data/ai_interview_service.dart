import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// POST /api/v1/interview/start — Starts session and returns initial greeting & Q1
  Future<StartInterviewResponse?> startInterview(StartInterviewRequest request) async {
    final delays = [0, 1, 3];
    for (int i = 0; i < delays.length; i++) {
      if (delays[i] > 0) await Future.delayed(Duration(seconds: delays[i]));
      try {
        final response = await _dio
            .post('/interview/start', data: request.toJson())
            .timeout(const Duration(seconds: 60));
        if (response.statusCode == 200 && response.data != null) {
          return StartInterviewResponse.fromJson(response.data);
        }
      } catch (e) {
        debugPrint('startInterview attempt ${i + 1} failed: $e');
        if (i == delays.length - 1) rethrow;
      }
    }
    return null;
  }

  /// POST /api/v1/interview/answer — Submits candidate answer, returns evaluation + Q(N+1)
  Future<AnswerResponse?> submitAnswer(AnswerRequest request) async {
    final delays = [0, 1];
    for (int i = 0; i < delays.length; i++) {
      if (delays[i] > 0) await Future.delayed(Duration(seconds: delays[i]));
      try {
        final response = await _dio
            .post('/interview/answer', data: request.toJson())
            .timeout(const Duration(seconds: 90));

        if (response.statusCode == 200 && response.data != null) {
          return AnswerResponse.fromJson(response.data);
        }
      } catch (e) {
        debugPrint('submitAnswer attempt ${i + 1} failed: $e');
        if (i == delays.length - 1) return null;
      }
    }
    return null;
  }

  /// POST /api/v1/interview/finish/{session_id} — Concludes interview & returns full report
  Future<InterviewFinishResponse?> finishInterview(String sessionId) async {
    final delays = [0, 1];
    for (int i = 0; i < delays.length; i++) {
      if (delays[i] > 0) await Future.delayed(Duration(seconds: delays[i]));
      try {
        final response = await _dio
            .post('/interview/finish/$sessionId')
            .timeout(const Duration(seconds: 45));
        if (response.statusCode == 200 && response.data != null) {
          return InterviewFinishResponse.fromJson(response.data);
        }
      } catch (e) {
        debugPrint('finishInterview attempt ${i + 1} failed: $e');
        if (i == delays.length - 1) return null;
      }
    }
    return null;
  }

  /// GET /api/v1/interview/history — Fetches candidate's past interview session reports
  Future<List<Map<String, dynamic>>> fetchInterviewHistory({String email = 'unii12634@gmail.com'}) async {
    // 1. Try Java Enterprise Backend
    try {
      final javaReports = await JavaApiService.fetchInterviewReports(email: email);
      if (javaReports != null && javaReports.isNotEmpty) {
        debugPrint('✅ Java Backend fetched ${javaReports.length} past interview reports!');
        return javaReports;
      }
    } catch (e) {
      debugPrint('Java backend history notice: $e');
    }

    // 2. Direct Supabase REST DB query
    try {
      final supabaseDio = Dio();
      final response = await supabaseDio.get(
        '$_supabaseUrl/rest/v1/ai_interview_reports?order=created_at.desc&limit=50',
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
          debugPrint('✅ Direct Supabase query fetched ${list.length} past interview reports!');
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

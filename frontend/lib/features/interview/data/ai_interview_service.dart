import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import 'models/ai_interview_models.dart';

// Re-export models for convenient imports across feature widgets
export 'models/ai_interview_models.dart';

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
          options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
          debugPrint('🌐 [API REQ] ${options.method} ${options.path}');
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

  /// GET /api/v1/health — Checks Render backend reachability and calculates latency
  Future<HealthResponse?> healthCheck() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get('/health').timeout(const Duration(seconds: 15));
      stopwatch.stop();
      if (response.statusCode == 200 && response.data != null) {
        return HealthResponse.fromJson(response.data, stopwatch.elapsedMilliseconds);
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('healthCheck error: $e');
    }
    return null;
  }

  /// Performs detailed health test with latency for diagnostic screens
  Future<Map<String, dynamic>> testDetailedHealth() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get('/health').timeout(const Duration(seconds: 15));
      stopwatch.stop();
      if (response.statusCode == 200 && response.data != null) {
        final data = Map<String, dynamic>.from(response.data);
        data['latency_ms'] = stopwatch.elapsedMilliseconds;
        data['is_healthy'] = true;
        return data;
      }
    } catch (e) {
      stopwatch.stop();
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
}

/// Compatibility typedef for AiInterviewService
typedef AiInterviewService = AiInterviewApiClient;

final aiInterviewServiceProvider = Provider<AiInterviewApiClient>((ref) {
  return AiInterviewApiClient();
});

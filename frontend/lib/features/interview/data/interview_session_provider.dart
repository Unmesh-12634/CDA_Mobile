import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_interview_service.dart';

class InterviewSessionState {
  final String? sessionId;
  final String currentQuestion;
  final String initialGreeting;
  final String transitionPhrase;
  final int turnNumber;
  final int totalQuestions;
  final bool isCompleted;
  final bool isInitializing;
  final bool isSubmittingAnswer;
  final String initializationStatus;
  final double? lastEvaluationScore;
  final String? lastFeedback;
  final Map<String, dynamic>? speechAnalytics;
  final String? errorMessage;
  final InterviewFinishResponse? finalReport;

  const InterviewSessionState({
    this.sessionId,
    this.currentQuestion = '',
    this.initialGreeting = '',
    this.transitionPhrase = '',
    this.turnNumber = 1,
    this.totalQuestions = 5,
    this.isCompleted = false,
    this.isInitializing = false,
    this.isSubmittingAnswer = false,
    this.initializationStatus = 'Ready',
    this.lastEvaluationScore,
    this.lastFeedback,
    this.speechAnalytics,
    this.errorMessage,
    this.finalReport,
  });

  InterviewSessionState copyWith({
    String? sessionId,
    String? currentQuestion,
    String? initialGreeting,
    String? transitionPhrase,
    int? turnNumber,
    int? totalQuestions,
    bool? isCompleted,
    bool? isInitializing,
    bool? isSubmittingAnswer,
    String? initializationStatus,
    double? lastEvaluationScore,
    String? lastFeedback,
    Map<String, dynamic>? speechAnalytics,
    String? errorMessage,
    InterviewFinishResponse? finalReport,
  }) {
    return InterviewSessionState(
      sessionId: sessionId ?? this.sessionId,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      initialGreeting: initialGreeting ?? this.initialGreeting,
      transitionPhrase: transitionPhrase ?? this.transitionPhrase,
      turnNumber: turnNumber ?? this.turnNumber,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      isCompleted: isCompleted ?? this.isCompleted,
      isInitializing: isInitializing ?? this.isInitializing,
      isSubmittingAnswer: isSubmittingAnswer ?? this.isSubmittingAnswer,
      initializationStatus: initializationStatus ?? this.initializationStatus,
      lastEvaluationScore: lastEvaluationScore ?? this.lastEvaluationScore,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      speechAnalytics: speechAnalytics ?? this.speechAnalytics,
      errorMessage: errorMessage ?? this.errorMessage,
      finalReport: finalReport ?? this.finalReport,
    );
  }
}

class InterviewSessionNotifier extends StateNotifier<InterviewSessionState> {
  final AiInterviewApiClient _apiClient;

  InterviewSessionNotifier(this._apiClient) : super(const InterviewSessionState());

  /// Starts live session on Render FastAPI backend and stores session_id
  Future<bool> startSession(StartInterviewRequest request) async {
    if (state.isInitializing) return false;
    state = state.copyWith(
      isInitializing: true,
      initializationStatus: 'Waking up AI Engine on Render...',
      errorMessage: null,
    );

    try {
      final isOnline = await _apiClient.waitForBackendReady(
        maxWaitSeconds: 90,
        onPhaseUpdate: (phase, message) {
          state = state.copyWith(initializationStatus: message);
        },
      );

      if (!isOnline) {
        state = state.copyWith(
          isInitializing: false,
          errorMessage: 'Backend engine offline or un-reachable on Render.',
        );
        return false;
      }

      final response = await _apiClient.startInterview(request);
      if (response != null && response.sessionId.isNotEmpty) {
        state = state.copyWith(
          sessionId: response.sessionId,
          currentQuestion: response.currentQuestion,
          initialGreeting: response.initialGreeting,
          transitionPhrase: response.transitionPhrase,
          turnNumber: response.turnNumber,
          totalQuestions: response.totalTargetQuestions,
          isCompleted: response.isCompleted,
          isInitializing: false,
          errorMessage: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isInitializing: false,
          errorMessage: 'Failed to obtain session ID from backend.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('startSession error: $e');
      state = state.copyWith(
        isInitializing: false,
        errorMessage: 'Connection error starting interview: $e',
      );
      return false;
    }
  }

  /// Submits answer asynchronously with atomic request guard against duplicates
  Future<AnswerResponse?> submitAnswer({
    required String candidateAnswer,
    double speakingDurationSec = 15.0,
  }) async {
    if (state.isSubmittingAnswer || state.sessionId == null || state.sessionId!.isEmpty) {
      return null;
    }

    state = state.copyWith(isSubmittingAnswer: true, errorMessage: null);

    try {
      final req = AnswerRequest(
        sessionId: state.sessionId!,
        candidateAnswer: candidateAnswer,
        speakingDurationSec: speakingDurationSec,
      );

      final response = await _apiClient.submitAnswer(req);

      if (response != null) {
        state = state.copyWith(
          isSubmittingAnswer: false,
          isCompleted: response.isCompleted,
          currentQuestion: response.currentQuestion ?? state.currentQuestion,
          turnNumber: response.turnNumber,
          totalQuestions: response.totalTargetQuestions,
          transitionPhrase: response.transitionPhrase,
          lastEvaluationScore: response.lastEvaluationScore ?? state.lastEvaluationScore,
          lastFeedback: response.lastFeedback ?? state.lastFeedback,
          speechAnalytics: response.speechAnalytics ?? state.speechAnalytics,
        );
        return response;
      } else {
        state = state.copyWith(
          isSubmittingAnswer: false,
          errorMessage: 'Failed to process answer with backend.',
        );
        return null;
      }
    } catch (e) {
      debugPrint('submitAnswer error: $e');
      state = state.copyWith(
        isSubmittingAnswer: false,
        errorMessage: 'Network error submitting answer: $e',
      );
      return null;
    }
  }

  /// Concludes interview session and retrieves final report from backend
  Future<InterviewFinishResponse?> finishSession() async {
    if (state.sessionId == null || state.sessionId!.isEmpty) return null;

    try {
      final report = await _apiClient.finishInterview(state.sessionId!);
      if (report != null) {
        state = state.copyWith(finalReport: report, isCompleted: true);
        return report;
      }
    } catch (e) {
      debugPrint('finishSession error: $e');
    }
    return null;
  }
}

final interviewSessionProvider =
    StateNotifierProvider<InterviewSessionNotifier, InterviewSessionState>((ref) {
  final apiClient = ref.watch(aiInterviewServiceProvider);
  return InterviewSessionNotifier(apiClient);
});

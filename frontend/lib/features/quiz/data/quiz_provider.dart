import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/network/java_api_service.dart';
import '../../profile/data/user_profile_provider.dart';
import '../../home/data/weekly_goal_provider.dart';


class QuizQuestion {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    } else {
      parsedOptions = ['Option A', 'Option B', 'Option C', 'Option D'];
    }

    while (parsedOptions.length < 4) {
      parsedOptions.add('Option ${String.fromCharCode(65 + parsedOptions.length)}');
    }

    return QuizQuestion(
      id: json['id']?.toString() ?? 'q_1',
      category: json['category']?.toString() ?? 'Technical Assessment',
      question: json['question']?.toString() ?? '',
      options: parsedOptions.take(4).toList(),
      correctOptionIndex: (json['correct_index'] as num?)?.toInt() ?? (json['correctOptionIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation']?.toString() ?? 'This answer follows industry-standard architectural best practices.',
    );
  }
}

class QuizState {
  final bool isLoading;
  final String skillFocus;
  final String weaknessSummary;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<int, int> selectedAnswers; // question index -> selected option index
  final bool isCompleted;
  final int score;
  final int todayCompleted;
  final int maxDailyLimit;

  const QuizState({
    this.isLoading = false,
    this.skillFocus = 'Full-Stack Software Engineering',
    this.weaknessSummary = 'System Design & Concurrency',
    required this.questions,
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.isCompleted = false,
    this.score = 0,
    this.todayCompleted = 0,
    this.maxDailyLimit = 5,
  });

  int get remainingToday => (maxDailyLimit - todayCompleted).clamp(0, maxDailyLimit);

  QuizState copyWith({
    bool? isLoading,
    String? skillFocus,
    String? weaknessSummary,
    List<QuizQuestion>? questions,
    int? currentIndex,
    Map<int, int>? selectedAnswers,
    bool? isCompleted,
    int? score,
    int? todayCompleted,
    int? maxDailyLimit,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      skillFocus: skillFocus ?? this.skillFocus,
      weaknessSummary: weaknessSummary ?? this.weaknessSummary,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
      todayCompleted: todayCompleted ?? this.todayCompleted,
      maxDailyLimit: maxDailyLimit ?? this.maxDailyLimit,
    );
  }

  QuizQuestion get currentQuestion => questions[currentIndex];
}

final sampleQuizQuestions = <QuizQuestion>[
  const QuizQuestion(
    id: 'q-1',
    category: 'System Design',
    question: 'Which rate limiting algorithm allows sudden bursts of traffic while guaranteeing a fixed long-term average rate?',
    options: ['Token Bucket Algorithm', 'Leaky Bucket Algorithm', 'Fixed Window Counter', 'Sliding Window Log'],
    correctOptionIndex: 0,
    explanation: 'The Token Bucket algorithm allows tokens to accumulate up to a maximum bucket size, permitting sudden bursts while enforcing the average rate.',
  ),
  const QuizQuestion(
    id: 'q-2',
    category: 'Concurrency',
    question: 'Which Java primitive is guaranteed to prevent memory visibility issues across CPU cores without synchronization lock overhead?',
    options: ['volatile', 'synchronized', 'AtomicInteger', 'ThreadLocal'],
    correctOptionIndex: 0,
    explanation: 'volatile ensures memory visibility — reads always see the latest write from any thread — without mutual exclusion lock overhead.',
  ),
  const QuizQuestion(
    id: 'q-3',
    category: 'Database Design',
    question: 'Which ACID property guarantees that database transactions are executed in isolated environments without intermediate state leakage?',
    options: ['Atomicity', 'Consistency', 'Isolation', 'Durability'],
    correctOptionIndex: 2,
    explanation: 'Isolation ensures concurrent transactions do not interfere with each other or read partial uncommitted data.',
  ),
  const QuizQuestion(
    id: 'q-4',
    category: 'API Resilience',
    question: 'In a Spring Boot microservice architecture, what is the primary benefit of deploying a Circuit Breaker with Resilience4j?',
    options: [
      'Compresses REST payload sizes over HTTP/2',
      'Prevents cascading service failures by temporarily halting requests to an unhealthy downstream dependency',
      'Automatically balances HTTP traffic across Kubernetes pods',
      'Encrypts inter-service communication tokens'
    ],
    correctOptionIndex: 1,
    explanation: 'A Circuit Breaker monitors failure rates and transitions to OPEN state when a service fails, preventing upstream thread pool exhaustion and cascading system outages.',
  ),
  const QuizQuestion(
    id: 'q-5',
    category: 'Distributed Caching',
    question: 'How do you effectively mitigate a Cache Stampede (Thundering Herd) when a high-traffic Redis key expires?',
    options: [
      'Use Mutex / Distributed Locks or probabilistic early cache recomputation (XFetch)',
      'Increase the Redis connection pool size by 10x',
      'Set all cache TTLs to exactly midnight',
      'Switch from Redis to local JVM in-memory HashMap'
    ],
    correctOptionIndex: 0,
    explanation: 'Using a distributed lock ensures only one worker thread regenerates the cache from the database, while XFetch algorithm probabilistically computes values before expiry.',
  ),
];

class QuizNotifier extends StateNotifier<QuizState> {
  final Ref ref;

  QuizNotifier(this.ref)
      : super(QuizState(questions: sampleQuizQuestions, isLoading: true)) {
    loadAiQuiz();
  }

  Future<void> loadAiQuiz({bool forceRefresh = false}) async {
    state = state.copyWith(
      isLoading: true,
      currentIndex: 0,
      selectedAnswers: {},
      isCompleted: false,
      score: 0,
    );

    final profile = ref.read(userProfileProvider);
    final email = profile.email.isNotEmpty ? profile.email : 'unii12634@gmail.com';

    // 1. Fetch today's attempts from Java backend
    int todayAttempts = 0;
    try {
      final attemptsData = await JavaApiService.fetchTodayQuizAttempts(email);
      if (attemptsData != null && attemptsData['todayCompleted'] != null) {
        todayAttempts = (attemptsData['todayCompleted'] as num).toInt();
      }
    } catch (_) {}

    // 2. Fetch fresh personalized questions from backend_ai
    try {
      final baseUrl = AppConfig.activeHost;
      final uri = Uri.parse('$baseUrl/api/v1/quiz/generate');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 18));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['data'] != null && json['data']['questions'] is List) {
          final rawList = json['data']['questions'] as List;
          final questions = rawList.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>)).toList();
          final skillFocus = json['data']['skill_focus']?.toString() ?? 'Full-Stack Software Engineering';
          final weaknessSummary = json['data']['weakness_summary']?.toString() ?? 'System Design & Concurrency';

          if (questions.isNotEmpty) {
            state = state.copyWith(
              isLoading: false,
              questions: questions,
              skillFocus: skillFocus,
              weaknessSummary: weaknessSummary,
              todayCompleted: todayAttempts,
            );
            return;
          }
        }
      }
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      questions: sampleQuizQuestions,
      todayCompleted: todayAttempts,
    );
  }

  void selectAnswer(int optionIndex) {
    if (state.selectedAnswers.containsKey(state.currentIndex)) return; // Already answered

    final updatedAnswers = Map<int, int>.from(state.selectedAnswers);
    updatedAnswers[state.currentIndex] = optionIndex;

    int newScore = state.score;
    if (optionIndex == state.currentQuestion.correctOptionIndex) {
      newScore += 20; // 20 points per question = 100 max
    }

    state = state.copyWith(
      selectedAnswers: updatedAnswers,
      score: newScore,
    );
  }

  Future<void> nextQuestion() async {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    } else {
      // 🏁 Quiz Finished!
      state = state.copyWith(isCompleted: true);

      // 1. Trigger streak progression (even 1 completed quiz fulfills the daily streak)
      ref.read(weeklyGoalProvider.notifier).completeToday();

      // 2. Persist result to database via Java backend
      final profile = ref.read(userProfileProvider);
      final email = profile.email.isNotEmpty ? profile.email : 'unii12634@gmail.com';
      int correctCount = 0;
      for (int i = 0; i < state.questions.length; i++) {
        if (state.selectedAnswers[i] == state.questions[i].correctOptionIndex) {
          correctCount++;
        }
      }

      try {
        await JavaApiService.saveQuizResult(
          email: email,
          score: state.score,
          correctCount: correctCount,
          totalQuestions: state.questions.length,
          category: state.weaknessSummary,
          skillFocus: state.skillFocus,
        );
      } catch (_) {}

      state = state.copyWith(todayCompleted: state.todayCompleted + 1);
    }
  }

  void restartQuiz() {
    loadAiQuiz(forceRefresh: true);
  }
}

final quizProvider = StateNotifierProvider.autoDispose<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref);
});

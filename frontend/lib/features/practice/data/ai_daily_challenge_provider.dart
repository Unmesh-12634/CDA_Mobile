import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/network/java_api_service.dart';
import '../../../core/services/ai_quiz_generator_service.dart';
import '../../auth/data/auth_provider.dart';
import '../../profile/data/user_profile_provider.dart';
import '../../home/data/weekly_goal_provider.dart';



class DrillQuestion {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  DrillQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory DrillQuestion.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    } else {
      parsedOptions = ['Option A', 'Option B', 'Option C', 'Option D'];
    }

    // Ensure exactly 4 options
    while (parsedOptions.length < 4) {
      parsedOptions.add('Option ${String.fromCharCode(65 + parsedOptions.length)}');
    }

    return DrillQuestion(
      id: json['id']?.toString() ?? 'q_1',
      category: json['category']?.toString() ?? 'Technical Core',
      question: json['question']?.toString() ?? '',
      options: parsedOptions.take(4).toList(),
      correctIndex: (json['correct_index'] as num?)?.toInt() ?? (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation']?.toString() ?? 'This option represents the industry standard engineering best practice.',
    );
  }
}

class AiDailyDrillModel {
  final String userEmail;
  final String skillFocus;
  final List<String> weakAreas;
  final String weaknessSummary;
  final List<DrillQuestion> questions;
  final int todayCompleted;
  final int maxDailyLimit;
  final bool canTakeDrill;

  AiDailyDrillModel({
    required this.userEmail,
    required this.skillFocus,
    required this.weakAreas,
    required this.weaknessSummary,
    required this.questions,
    this.todayCompleted = 0,
    this.maxDailyLimit = 5,
    this.canTakeDrill = true,
  });

  int get remainingToday => (maxDailyLimit - todayCompleted).clamp(0, maxDailyLimit);

  factory AiDailyDrillModel.fromJson(Map<String, dynamic> json, String email, {int todayCompleted = 0}) {
    final rawList = json['questions'] as List? ?? [];
    final parsedQuestions = rawList.map((q) => DrillQuestion.fromJson(q as Map<String, dynamic>)).toList();

    return AiDailyDrillModel(
      userEmail: email,
      skillFocus: json['skill_focus']?.toString() ?? 'Full-Stack Engineering',
      weakAreas: (json['weak_areas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      weaknessSummary: json['weakness_summary']?.toString() ?? 'Targeting past interview gaps',
      questions: parsedQuestions.isNotEmpty ? parsedQuestions : _fallbackDrillQuestions(),
      todayCompleted: todayCompleted,
      maxDailyLimit: 5,
      canTakeDrill: todayCompleted < 5,
    );
  }

  static List<DrillQuestion> _fallbackDrillQuestions() {
    return [
      DrillQuestion(
        id: 'q_1',
        category: 'System Design',
        question: 'Which rate limiting algorithm allows burst traffic while strictly enforcing a fixed long-term average rate limit?',
        options: [
          'Token Bucket Algorithm',
          'Leaky Bucket Algorithm',
          'Fixed Window Counter',
          'Sliding Window Log',
        ],
        correctIndex: 0,
        explanation: 'Token Bucket permits tokens to accumulate up to a maximum bucket capacity, allowing short bursts of requests while strictly throttling long-term request rates.',
      ),
      DrillQuestion(
        id: 'q_2',
        category: 'Concurrency',
        question: 'Which mechanism in Java ensures memory visibility across CPU cores without the overhead of mutual exclusion locks?',
        options: [
          'volatile keyword',
          'synchronized block',
          'ReentrantLock',
          'ThreadLocal storage',
        ],
        correctIndex: 0,
        explanation: 'The volatile keyword establishes a happens-before relationship, guaranteeing that reads from all threads immediately see the most recent write without acquiring a heavy monitor lock.',
      ),
      DrillQuestion(
        id: 'q_3',
        category: 'Database Architecture',
        question: 'When designing high-throughput PostgreSQL tables, why should you prefer Optimistic Concurrency Control (OCC) over Pessimistic Row Locking?',
        options: [
          'OCC eliminates row-level database locks and reduces connection wait times under high read-to-write ratios',
          'OCC automatically retries failed database transactions at the storage engine level',
          'OCC uses less RAM by disabling Write-Ahead Logging (WAL)',
          'OCC prevents dirty reads without requiring transaction isolation',
        ],
        correctIndex: 0,
        explanation: 'Optimistic Locking checks a version column at commit time without holding exclusive locks during transaction execution, maximizing database throughput when write collisions are rare.',
      ),
      DrillQuestion(
        id: 'q_4',
        category: 'API Resilience',
        question: 'In a Spring Boot microservice architecture, what is the primary benefit of deploying a Circuit Breaker with Resilience4j?',
        options: [
          'Compresses REST payload sizes over HTTP/2',
          'Prevents cascading service failures by temporarily halting requests to an unhealthy downstream dependency',
          'Automatically balances HTTP traffic across Kubernetes pods',
          'Encrypts inter-service communication tokens',
        ],
        correctIndex: 1,
        explanation: 'A Circuit Breaker monitors failure rates and transitions to OPEN state when a service fails, preventing upstream thread pool exhaustion and cascading system outages.',
      ),
      DrillQuestion(
        id: 'q_5',
        category: 'Distributed Caching',
        question: 'How do you effectively mitigate a Cache Stampede (Thundering Herd) when a high-traffic Redis key expires?',
        options: [
          'Use Mutex / Distributed Locks or probabilistic early cache recomputation (XFetch)',
          'Increase the Redis connection pool size by 10x',
          'Set all cache TTLs to exactly midnight',
          'Switch from Redis to local JVM in-memory HashMap',
        ],
        correctIndex: 0,
        explanation: 'Using a distributed lock ensures only one worker thread regenerates the cache from the database, while XFetch algorithm probabilistically computes values before expiry.',
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// StateNotifier for Drill State & Quiz Execution
// ─────────────────────────────────────────────────────────────
class DailyDrillState {
  final bool isLoading;
  final String? errorMessage;
  final AiDailyDrillModel? drill;
  final int currentQuestionIndex; // 0 to 4
  final Map<int, int> selectedOptions; // questionIndex -> selectedOptionIndex (0-3)
  final bool isCompleted;
  final int score; // 0 to 100
  final bool isSavingResult;

  DailyDrillState({
    this.isLoading = true,
    this.errorMessage,
    this.drill,
    this.currentQuestionIndex = 0,
    this.selectedOptions = const {},
    this.isCompleted = false,
    this.score = 0,
    this.isSavingResult = false,
  });

  DailyDrillState copyWith({
    bool? isLoading,
    String? errorMessage,
    AiDailyDrillModel? drill,
    int? currentQuestionIndex,
    Map<int, int>? selectedOptions,
    bool? isCompleted,
    int? score,
    bool? isSavingResult,
  }) {
    return DailyDrillState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      drill: drill ?? this.drill,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
      isSavingResult: isSavingResult ?? this.isSavingResult,
    );
  }

  DrillQuestion? get currentQuestion {
    if (drill == null || drill!.questions.isEmpty) return null;
    if (currentQuestionIndex < drill!.questions.length) {
      return drill!.questions[currentQuestionIndex];
    }
    return drill!.questions.last;
  }

  int get correctCount {
    if (drill == null) return 0;
    int count = 0;
    for (int i = 0; i < drill!.questions.length; i++) {
      if (selectedOptions[i] == drill!.questions[i].correctIndex) {
        count++;
      }
    }
    return count;
  }
}

class DailyDrillNotifier extends StateNotifier<DailyDrillState> {
  final Ref ref;

  DailyDrillNotifier(this.ref) : super(DailyDrillState(isLoading: true)) {
    loadFreshDrill();
  }

  Future<void> loadFreshDrill({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isCompleted: false, selectedOptions: {}, currentQuestionIndex: 0, score: 0);

    final profile = ref.read(userProfileProvider);
    final email = profile.email.isNotEmpty ? profile.email : ref.read(authProvider).email;

    // 1. Fetch today's completed attempts from Java backend
    int todayAttempts = 0;
    try {
      final attemptsData = await JavaApiService.fetchTodayQuizAttempts(email);
      if (attemptsData != null && attemptsData['todayCompleted'] != null) {
        todayAttempts = (attemptsData['todayCompleted'] as num).toInt();
      }
    } catch (_) {}

    // 2. Generate Real-time AI Questions via Groq AI Engine
    try {
      final drillModel = await AiQuizGeneratorService.generatePersonalizedDrill(
        email: email,
        todayCompleted: todayAttempts,
      );
      state = state.copyWith(isLoading: false, drill: drillModel);
      return;
    } catch (e) {
      debugPrint('AI Drill direct generation notice: $e');
    }

    // 3. Secondary attempt via Python backend if direct call had network glitch
    try {
      final baseUrl = AppConfig.activeHost;
      final uri = Uri.parse('$baseUrl/api/v1/quiz/generate');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['data'] != null) {
          final model = AiDailyDrillModel.fromJson(
            json['data'] as Map<String, dynamic>,
            email,
            todayCompleted: todayAttempts,
          );
          state = state.copyWith(isLoading: false, drill: model);
          return;
        }
      }
    } catch (_) {}

    // Dynamic procedural fallback if offline
    final fallbackModel = AiDailyDrillModel(
      userEmail: email,
      skillFocus: profile.targetRole.isNotEmpty ? profile.targetRole : 'Java & Spring Boot Engineer',
      weakAreas: ['System Design & Scalability', 'Concurrency & Deadlocks', 'PostgreSQL Optimizations'],
      weaknessSummary: 'Targeting System Design & Concurrency',
      questions: AiDailyDrillModel._fallbackDrillQuestions(),
      todayCompleted: todayAttempts,
      maxDailyLimit: 5,
      canTakeDrill: todayAttempts < 5,
    );

    state = state.copyWith(isLoading: false, drill: fallbackModel);
  }


  void selectOption(int optionIndex) {
    if (state.selectedOptions.containsKey(state.currentQuestionIndex)) return; // Already answered

    final updated = Map<int, int>.from(state.selectedOptions);
    updated[state.currentQuestionIndex] = optionIndex;

    int newScore = state.score;
    final currentQ = state.currentQuestion;
    if (currentQ != null && optionIndex == currentQ.correctIndex) {
      newScore += 20; // 5 questions * 20 = 100 points
    }

    state = state.copyWith(
      selectedOptions: updated,
      score: newScore,
    );
  }

  Future<void> nextQuestionOrFinish() async {
    final drill = state.drill;
    if (drill == null) return;

    if (state.currentQuestionIndex < drill.questions.length - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    } else {
      // 🏁 Drill Completed!
      state = state.copyWith(isCompleted: true, isSavingResult: true);

      // 1. Maintain / Increment 7-day streak (completing 1 drill secures the streak!)
      ref.read(weeklyGoalProvider.notifier).completeToday();

      // 2. Persist result to database via Java backend
      final email = drill.userEmail;
      final score = state.score;
      final correctCount = state.correctCount;
      final total = drill.questions.length;
      final category = drill.weaknessSummary;
      final skillFocus = drill.skillFocus;

      try {
        await JavaApiService.saveQuizResult(
          email: email,
          score: score,
          correctCount: correctCount,
          totalQuestions: total,
          category: category,
          skillFocus: skillFocus,
        );
      } catch (_) {}

      // Update attempt count in state
      final newTodayCount = drill.todayCompleted + 1;
      final updatedDrill = AiDailyDrillModel(
        userEmail: email,
        skillFocus: skillFocus,
        weakAreas: drill.weakAreas,
        weaknessSummary: drill.weaknessSummary,
        questions: drill.questions,
        todayCompleted: newTodayCount,
        maxDailyLimit: 5,
        canTakeDrill: newTodayCount < 5,
      );

      state = state.copyWith(isSavingResult: false, drill: updatedDrill);
    }
  }
}

final dailyDrillProvider = StateNotifierProvider.autoDispose<DailyDrillNotifier, DailyDrillState>((ref) {
  return DailyDrillNotifier(ref);
});

// Alias for home card and backward compatibility
final dailyChallengeProvider = FutureProvider.autoDispose<DailyDrillModelForCard>((ref) async {
  final drillState = ref.watch(dailyDrillProvider);
  final drill = drillState.drill;
  
  if (drill != null) {
    return DailyDrillModelForCard(
      targetSkill: drill.skillFocus,
      weaknessFocus: drill.weaknessSummary,
      todayCompleted: drill.todayCompleted,
      maxDailyLimit: drill.maxDailyLimit,
      remainingToday: drill.remainingToday,
      canTakeDrill: drill.canTakeDrill,
    );
  }

  return DailyDrillModelForCard(
    targetSkill: 'Java & Spring Boot',
    weaknessFocus: 'System Design & Concurrency',
    todayCompleted: 0,
    maxDailyLimit: 5,
    remainingToday: 5,
    canTakeDrill: true,
  );
});

class DailyDrillModelForCard {
  final String targetSkill;
  final String weaknessFocus;
  final int todayCompleted;
  final int maxDailyLimit;
  final int remainingToday;
  final bool canTakeDrill;

  DailyDrillModelForCard({
    required this.targetSkill,
    required this.weaknessFocus,
    required this.todayCompleted,
    required this.maxDailyLimit,
    required this.remainingToday,
    required this.canTakeDrill,
  });
}

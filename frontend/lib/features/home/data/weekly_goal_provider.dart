import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../quiz/data/quiz_provider.dart';

class WeeklyGoal {
  final int targetDays;
  final List<bool> completedDays;
  final int completedDaysCount;
  final double progressPercent;
  final String nextGoalSuggestion;
  final int totalHoursLearned;
  final int streakCount;
  final DateTime weekStartDate;

  const WeeklyGoal({
    this.targetDays = 5,
    this.completedDays = const [true, true, true, false, false, false, false],
    this.completedDaysCount = 3,
    this.progressPercent = 0.60,
    this.nextGoalSuggestion = "Complete today's quiz",
    this.totalHoursLearned = 14,
    this.streakCount = 5,
    required this.weekStartDate,
  });

  WeeklyGoal copyWith({
    int? targetDays,
    List<bool>? completedDays,
    int? completedDaysCount,
    double? progressPercent,
    String? nextGoalSuggestion,
    int? totalHoursLearned,
    int? streakCount,
    DateTime? weekStartDate,
  }) {
    return WeeklyGoal(
      targetDays: targetDays ?? this.targetDays,
      completedDays: completedDays ?? this.completedDays,
      completedDaysCount: completedDaysCount ?? this.completedDaysCount,
      progressPercent: progressPercent ?? this.progressPercent,
      nextGoalSuggestion: nextGoalSuggestion ?? this.nextGoalSuggestion,
      totalHoursLearned: totalHoursLearned ?? this.totalHoursLearned,
      streakCount: streakCount ?? this.streakCount,
      weekStartDate: weekStartDate ?? this.weekStartDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetDays': targetDays,
      'completedDays': completedDays,
      'totalHoursLearned': totalHoursLearned,
      'streakCount': streakCount,
      'weekStartDate': weekStartDate.toIso8601String(),
    };
  }

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) {
    final completed = List<bool>.from(json['completedDays'] as List);
    final completedCount = completed.where((d) => d).length;
    final target = json['targetDays'] as int? ?? 5;
    return WeeklyGoal(
      targetDays: target,
      completedDays: completed,
      completedDaysCount: completedCount,
      progressPercent: completedCount / target,
      nextGoalSuggestion: _getSuggestion(completed, completedCount, target),
      totalHoursLearned: json['totalHoursLearned'] as int? ?? (completedCount * 4 + 2),
      streakCount: json['streakCount'] as int? ?? 5,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
    );
  }

  static String _getSuggestion(List<bool> completed, int count, int target) {
    final todayIdx = DateTime.now().weekday - 1;
    final completedToday = todayIdx >= 0 && todayIdx < 7 ? completed[todayIdx] : false;

    if (!completedToday) {
      return "Complete today's daily quiz challenge";
    }
    if (count >= target) {
      return "Weekly learning goal completed! 🎉";
    }
    return "Great job! Watch today's learning reel or start an AI interview session";
  }
}

class WeeklyGoalNotifier extends StateNotifier<WeeklyGoal> {
  final Ref ref;

  WeeklyGoalNotifier(this.ref) : super(_defaultState()) {
    // Automatically listen to the quiz completion state
    ref.listen<QuizState>(quizProvider, (previous, next) {
      if (next.isCompleted && next.score >= 60) {
        completeToday();
      }
    });

    _loadState();
  }

  static DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  static WeeklyGoal _defaultState() {
    final now = DateTime.now();
    return WeeklyGoal(
      targetDays: 5,
      completedDays: const [true, true, true, false, false, false, false],
      completedDaysCount: 3,
      progressPercent: 0.60,
      nextGoalSuggestion: "Complete today's daily quiz challenge",
      totalHoursLearned: 14,
      streakCount: 5,
      weekStartDate: _getStartOfWeek(now),
    );
  }

  Future<void> _loadState() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.getWeeklyGoal();
      if (raw != null) {
        final Map<String, dynamic> json = jsonDecode(raw);
        final loaded = WeeklyGoal.fromJson(json);
        
        // Check if we are in a new week
        final currentWeekStart = _getStartOfWeek(DateTime.now());
        if (loaded.weekStartDate.year != currentWeekStart.year ||
            loaded.weekStartDate.month != currentWeekStart.month ||
            loaded.weekStartDate.day != currentWeekStart.day) {
          // It's a new week! Reset completed days but preserve streak
          final resetGoal = WeeklyGoal(
            targetDays: loaded.targetDays,
            completedDays: const [false, false, false, false, false, false, false],
            completedDaysCount: 0,
            progressPercent: 0.0,
            nextGoalSuggestion: "Complete today's daily quiz challenge",
            totalHoursLearned: 0,
            streakCount: loaded.streakCount,
            weekStartDate: currentWeekStart,
          );
          state = resetGoal;
          await _saveState();
        } else {
          state = loaded;
        }
      } else {
        // No stored state, save default state
        await _saveState();
      }
    } catch (_) {
      // Fallback to default state on error
    }
  }

  Future<void> _saveState() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = jsonEncode(state.toJson());
      await storage.saveWeeklyGoal(raw);
    } catch (_) {}
  }

  Future<void> completeToday() async {
    final todayIdx = DateTime.now().weekday - 1;
    if (todayIdx < 0 || todayIdx > 6) return;

    if (state.completedDays[todayIdx]) return; // Already completed today

    final updated = List<bool>.from(state.completedDays);
    updated[todayIdx] = true;

    final completedCount = updated.where((d) => d).length;
    final totalHours = completedCount * 4 + 2; // E.g. 4 hours per completed day + 2 base hours

    state = state.copyWith(
      completedDays: updated,
      completedDaysCount: completedCount,
      progressPercent: completedCount / state.targetDays,
      totalHoursLearned: totalHours,
      nextGoalSuggestion: WeeklyGoal._getSuggestion(updated, completedCount, state.targetDays),
      streakCount: state.streakCount + (state.completedDays[todayIdx] ? 0 : 1),
    );

    await _saveState();
  }

  Future<void> resetWeeklyProgress() async {
    final reset = WeeklyGoal(
      targetDays: 5,
      completedDays: const [false, false, false, false, false, false, false],
      completedDaysCount: 0,
      progressPercent: 0.0,
      nextGoalSuggestion: "Complete today's daily quiz challenge",
      totalHoursLearned: 0,
      streakCount: 0,
      weekStartDate: _getStartOfWeek(DateTime.now()),
    );
    state = reset;
    await _saveState();
  }
}

final weeklyGoalProvider = StateNotifierProvider<WeeklyGoalNotifier, WeeklyGoal>((ref) {
  return WeeklyGoalNotifier(ref);
});

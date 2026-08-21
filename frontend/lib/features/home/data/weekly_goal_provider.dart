import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/network/java_api_service.dart';
import '../../../core/services/study_time_tracker_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../quiz/data/quiz_provider.dart';

class WeeklyGoal {
  final int targetDays;
  final List<bool> completedDays; // 7 days: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final int completedDaysCount;
  final double progressPercent;
  final String nextGoalSuggestion;
  final int totalHoursLearned;
  final int streakCount;
  final DateTime weekStartDate;
  final String? lastActiveDate;

  const WeeklyGoal({
    this.targetDays = 7,
    this.completedDays = const [false, false, false, false, false, false, false],
    this.completedDaysCount = 0,
    this.progressPercent = 0.0,
    this.nextGoalSuggestion = "Practice today's challenge to keep your 7-day streak alive 🔥",
    this.totalHoursLearned = 0,
    this.streakCount = 0,
    required this.weekStartDate,
    this.lastActiveDate,
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
    String? lastActiveDate,
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
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetDays': targetDays,
      'completedDays': completedDays,
      'totalHoursLearned': totalHoursLearned,
      'streakCount': streakCount,
      'weekStartDate': weekStartDate.toIso8601String(),
      'lastActiveDate': lastActiveDate,
    };
  }

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) {
    List<bool> completed = [false, false, false, false, false, false, false];
    if (json['completedDays'] is List) {
      final list = json['completedDays'] as List;
      completed = List<bool>.generate(7, (i) => i < list.length ? (list[i] == true) : false);
    }
    final completedCount = completed.where((d) => d).length;
    final target = json['targetDays'] as int? ?? 7;
    final streak = json['streakCount'] as int? ?? 0;
    final hours = json['totalHoursLearned'] as int? ?? (completedCount * 2);
    final lastActive = json['lastActiveDate'] as String?;

    return WeeklyGoal(
      targetDays: target,
      completedDays: completed,
      completedDaysCount: completedCount,
      progressPercent: target > 0 ? (completedCount / target).clamp(0.0, 1.0) : 0.0,
      nextGoalSuggestion: _getSuggestion(completed, completedCount, target),
      totalHoursLearned: hours,
      streakCount: streak,
      weekStartDate: json['weekStartDate'] != null
          ? DateTime.parse(json['weekStartDate'] as String)
          : _getStartOfWeek(DateTime.now()),
      lastActiveDate: lastActive,
    );
  }

  static DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  static String _getSuggestion(List<bool> completed, int count, int target) {
    final todayIdx = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
    final completedToday = todayIdx >= 0 && todayIdx < 7 ? completed[todayIdx] : false;

    if (!completedToday) {
      return "Practice today's challenge to keep your 7-day streak alive 🔥";
    }
    if (count >= target) {
      return "7-Day Full Learning Goal Achieved! 🏆 Outstanding consistency!";
    }
    return "Great work today! Continue watching learning reels or take an AI mock interview ⭐";
  }
}

class WeeklyGoalNotifier extends StateNotifier<WeeklyGoal> {
  final Ref ref;

  WeeklyGoalNotifier(this.ref) : super(_defaultState()) {
    // Automatically listen to quiz completion state
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
      targetDays: 7,
      completedDays: const [false, false, false, false, false, false, false],
      completedDaysCount: 0,
      progressPercent: 0.0,
      nextGoalSuggestion: "Practice today's challenge to keep your 7-day streak alive 🔥",
      totalHoursLearned: 0,
      streakCount: 0,
      weekStartDate: _getStartOfWeek(now),
    );
  }

  /// Calculates accurate streak based on last active date and missed days
  int _calculateActiveStreak({required int rawStreak, String? lastActiveStr}) {
    if (lastActiveStr == null || lastActiveStr.isEmpty) return rawStreak;
    try {
      final lastDate = DateTime.parse(lastActiveStr);
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastActiveClean = DateTime(lastDate.year, lastDate.month, lastDate.day);

      final diffDays = todayDate.difference(lastActiveClean).inDays;
      if (diffDays > 1) {
        // User missed at least 1 whole day! Streak resets to 0 until practiced today
        debugPrint('⚠️ Streak broken: last active was $diffDays days ago ($lastActiveClean). Resetting streak to 0.');
        return 0;
      }
      return rawStreak;
    } catch (_) {
      return rawStreak;
    }
  }

  Future<void> _loadState() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final cachedEmail = LocalCacheService().get<String>('cda_auth_email');
      final email = user?.email ?? cachedEmail ?? '';
      if (email.isEmpty) return;

      // 1. Try Java Enterprise Backend first
      try {
        final javaGoal = await JavaApiService.fetchLearningGoals(email: email);
        if (javaGoal != null) {
          final rawStreak = javaGoal['streak_count'] as int? ?? 0;
          final lastActive = javaGoal['last_active_date'] as String?;
          final streak = _calculateActiveStreak(rawStreak: rawStreak, lastActiveStr: lastActive);
          final hours = (javaGoal['total_hours_learned'] as num?)?.toInt() ?? 0;

          List<bool> days = [false, false, false, false, false, false, false];
          if (javaGoal['weekly_days_completed'] is List) {
            final raw = javaGoal['weekly_days_completed'] as List;
            days = List<bool>.generate(7, (i) => i < raw.length ? (raw[i] == true) : false);
          }

          final now = DateTime.now();
          final startOfWeek = _getStartOfWeek(now);
          final completedCount = days.where((d) => d).length;

          state = WeeklyGoal(
            targetDays: 7,
            completedDays: days,
            completedDaysCount: completedCount,
            progressPercent: completedCount / 7.0,
            nextGoalSuggestion: javaGoal['next_goal_suggestion']?.toString() ??
                WeeklyGoal._getSuggestion(days, completedCount, 7),
            totalHoursLearned: hours,
            streakCount: streak,
            weekStartDate: startOfWeek,
            lastActiveDate: lastActive,
          );
          debugPrint('✅ Loaded 7-day progress via Java Backend Service!');
          return;
        }
      } catch (e) {
        debugPrint('Java backend progress fetch notice: $e');
      }

      // 2. Direct Supabase DB Fallback
      try {
        final res = await SupabaseConfig.client
            .from('users')
            .select('current_streak, weekly_days_completed, total_study_minutes, total_active_seconds, last_active_date')
            .eq('email', email)
            .maybeSingle();

        if (res != null) {
          final rawStreak = res['current_streak'] as int? ?? 0;
          final lastActive = res['last_active_date']?.toString();
          final streak = _calculateActiveStreak(rawStreak: rawStreak, lastActiveStr: lastActive);
          final dbMinutes = res['total_study_minutes'] as int? ?? 0;
          final dbSeconds = res['total_active_seconds'] as int? ?? (dbMinutes * 60);

          // Populate cache if DB has newer values
          final cachedSeconds = LocalCacheService().get<int>('cda_total_active_seconds') ?? 0;
          if (dbSeconds > cachedSeconds) {
            await LocalCacheService().set('cda_total_active_seconds', dbSeconds);
            await LocalCacheService().set('cda_total_study_minutes', dbMinutes);
          }

          List<bool> days = [false, false, false, false, false, false, false];
          if (res['weekly_days_completed'] is List) {
            final raw = res['weekly_days_completed'] as List;
            days = List<bool>.generate(7, (i) => i < raw.length ? (raw[i] == true) : false);
          }

          final now = DateTime.now();
          final startOfWeek = _getStartOfWeek(now);
          final completedCount = days.where((d) => d).length;
          final actualHours = (dbMinutes ~/ 60);

          state = WeeklyGoal(
            targetDays: 7,
            completedDays: days,
            completedDaysCount: completedCount,
            progressPercent: completedCount / 7.0,
            nextGoalSuggestion: WeeklyGoal._getSuggestion(days, completedCount, 7),
            totalHoursLearned: actualHours,
            streakCount: streak,
            weekStartDate: startOfWeek,
            lastActiveDate: lastActive,
          );
          debugPrint('✅ Loaded 7-day learning goal from Supabase DB (${dbMinutes}m / ${actualHours}h)!');
          return;
        }
      } catch (e) {
        debugPrint('Supabase 7-day goal fetch notice: $e');
      }

      // 3. Fallback to secure storage
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.getWeeklyGoal();
      if (raw != null) {
        final Map<String, dynamic> json = jsonDecode(raw);
        final loaded = WeeklyGoal.fromJson(json);

        final currentWeekStart = _getStartOfWeek(DateTime.now());
        if (loaded.weekStartDate.year != currentWeekStart.year ||
            loaded.weekStartDate.month != currentWeekStart.month ||
            loaded.weekStartDate.day != currentWeekStart.day) {
          state = WeeklyGoal(
            targetDays: 7,
            completedDays: const [false, false, false, false, false, false, false],
            completedDaysCount: 0,
            progressPercent: 0.0,
            nextGoalSuggestion: "Practice today's challenge to keep your 7-day streak alive 🔥",
            totalHoursLearned: 0,
            streakCount: _calculateActiveStreak(rawStreak: loaded.streakCount, lastActiveStr: loaded.lastActiveDate),
            weekStartDate: currentWeekStart,
          );
          await _saveState();
        } else {
          state = loaded;
        }
      }
    } catch (e) {
      debugPrint('Error loading weekly goal state: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.saveWeeklyGoal(jsonEncode(state.toJson()));

      final user = SupabaseConfig.client.auth.currentUser;
      final cachedEmail = LocalCacheService().get<String>('cda_auth_email');
      final email = user?.email ?? cachedEmail ?? '';
      if (email.isEmpty) return;
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // Call Java backend
      JavaApiService.completeTodayGoal(email: email);

      await SupabaseConfig.client.from('users').update({
        'current_streak': state.streakCount,
        'weekly_days_completed': state.completedDays,
        'last_active_date': todayStr,
      }).eq('email', email);

      // Sync to Supabase user_weekly_report table
      try {
        final startOfWeekStr = state.weekStartDate.toIso8601String().split('T')[0];
        await SupabaseConfig.client.from('user_weekly_report').upsert({
          'user_email': email,
          'week_start_date': startOfWeekStr,
          'total_study_minutes': state.totalHoursLearned * 60,
          'streak_maintained_days': state.completedDaysCount,
          'weekly_grade': state.completedDaysCount >= 5 ? 'A' : (state.completedDaysCount >= 3 ? 'B' : 'C'),
        });
      } catch (_) {}

      // Sync active subscription tier to Supabase user_subscription table
      try {
        await SupabaseConfig.client.from('user_subscription').upsert({
          'user_email': email,
          'plan_tier': 'Pro',
          'status': 'Active',
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      debugPrint('✅ Synced 7-day learning streak to Database & Java Backend!');
    } catch (e) {
      debugPrint('Error saving 7-day goal state: $e');
    }
  }

  /// Completes today's goal (e.g. from Quiz, AI Interview, or Jobs practice)
  Future<void> completeToday() async {
    final now = DateTime.now();
    final todayIdx = now.weekday - 1; // 0=Mon, 6=Sun

    if (todayIdx < 0 || todayIdx >= 7) return;

    final updatedDays = List<bool>.from(state.completedDays);
    final wasAlreadyCompleted = updatedDays[todayIdx];
    updatedDays[todayIdx] = true;

    final todayStr = now.toIso8601String().split('T')[0];
    int newStreak;

    if (wasAlreadyCompleted) {
      newStreak = state.streakCount > 0 ? state.streakCount : 1;
    } else {
      // Check if last active was yesterday or older
      if (state.lastActiveDate != null && state.lastActiveDate!.isNotEmpty) {
        try {
          final lastDate = DateTime.parse(state.lastActiveDate!);
          final todayClean = DateTime(now.year, now.month, now.day);
          final lastClean = DateTime(lastDate.year, lastDate.month, lastDate.day);
          final diff = todayClean.difference(lastClean).inDays;

          if (diff == 1) {
            // Consecutive day! Streak increases
            newStreak = state.streakCount + 1;
          } else if (diff == 0) {
            newStreak = state.streakCount > 0 ? state.streakCount : 1;
          } else {
            // Missed at least 1 day! Streak resets to 1 (starting fresh today)
            newStreak = 1;
          }
        } catch (_) {
          newStreak = state.streakCount + 1;
        }
      } else {
        newStreak = 1;
      }
    }

    final completedCount = updatedDays.where((d) => d).length;

    final realHours = StudyTimeTrackerService().getTotalStudyHours().floor();
    final totalHours = realHours > state.totalHoursLearned ? realHours : state.totalHoursLearned;

    state = state.copyWith(
      targetDays: 7,
      completedDays: updatedDays,
      completedDaysCount: completedCount,
      progressPercent: (completedCount / 7.0).clamp(0.0, 1.0),
      streakCount: newStreak,
      totalHoursLearned: totalHours,
      nextGoalSuggestion: WeeklyGoal._getSuggestion(updatedDays, completedCount, 7),
      lastActiveDate: todayStr,
    );

    await _saveState();
  }

  Future<void> toggleDay(int index) async {
    if (index < 0 || index >= 7) return;

    final updatedDays = List<bool>.from(state.completedDays);
    updatedDays[index] = !updatedDays[index];

    final completedCount = updatedDays.where((d) => d).length;
    state = state.copyWith(
      targetDays: 7,
      completedDays: updatedDays,
      completedDaysCount: completedCount,
      progressPercent: (completedCount / 7.0).clamp(0.0, 1.0),
      nextGoalSuggestion: WeeklyGoal._getSuggestion(updatedDays, completedCount, 7),
    );

    await _saveState();
  }

  Future<void> resetWeek() async {
    state = WeeklyGoal(
      targetDays: 7,
      completedDays: const [false, false, false, false, false, false, false],
      completedDaysCount: 0,
      progressPercent: 0.0,
      nextGoalSuggestion: "Practice today's challenge to keep your 7-day streak alive 🔥",
      totalHoursLearned: 0,
      streakCount: 0,
      weekStartDate: _getStartOfWeek(DateTime.now()),
    );
    await _saveState();
  }
}

final weeklyGoalProvider =
    StateNotifierProvider<WeeklyGoalNotifier, WeeklyGoal>((ref) {
  return WeeklyGoalNotifier(ref);
});

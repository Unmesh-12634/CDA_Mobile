import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_haptics.dart';

class ScreenTimeState {
  final int todayActiveSeconds;
  final int dailyTargetMinutes;
  final List<int> weeklyMinutes; // 7 days: Mon-Sun
  final bool hasNotifiedHalfway;
  final bool hasNotifiedCompleted;

  const ScreenTimeState({
    this.todayActiveSeconds = 0,
    this.dailyTargetMinutes = 60, // 1 hour default daily study goal
    this.weeklyMinutes = const [0, 0, 0, 0, 0, 0, 0],
    this.hasNotifiedHalfway = false,
    this.hasNotifiedCompleted = false,
  });

  int get todayMinutes => (todayActiveSeconds / 60).floor();
  double get todayHours => todayActiveSeconds / 3600.0;
  double get progressPercent => dailyTargetMinutes > 0
      ? (todayMinutes / dailyTargetMinutes).clamp(0.0, 1.0)
      : 0.0;
  bool get isGoalCompleted => todayMinutes >= dailyTargetMinutes;

  String get formattedTodayTime {
    final hrs = todayMinutes ~/ 60;
    final mins = todayMinutes % 60;
    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    }
    return '${mins}m';
  }

  String get formattedTargetTime {
    final hrs = dailyTargetMinutes ~/ 60;
    final mins = dailyTargetMinutes % 60;
    if (hrs > 0 && mins > 0) {
      return '${hrs}h ${mins}m';
    } else if (hrs > 0) {
      return '${hrs}h';
    }
    return '${mins}m';
  }

  ScreenTimeState copyWith({
    int? todayActiveSeconds,
    int? dailyTargetMinutes,
    List<int>? weeklyMinutes,
    bool? hasNotifiedHalfway,
    bool? hasNotifiedCompleted,
  }) {
    return ScreenTimeState(
      todayActiveSeconds: todayActiveSeconds ?? this.todayActiveSeconds,
      dailyTargetMinutes: dailyTargetMinutes ?? this.dailyTargetMinutes,
      weeklyMinutes: weeklyMinutes ?? this.weeklyMinutes,
      hasNotifiedHalfway: hasNotifiedHalfway ?? this.hasNotifiedHalfway,
      hasNotifiedCompleted: hasNotifiedCompleted ?? this.hasNotifiedCompleted,
    );
  }
}

class ScreenTimeNotifier extends StateNotifier<ScreenTimeState> with WidgetsBindingObserver {
  Timer? _tickerTimer;
  Timer? _dbFlushTimer;
  bool _isInForeground = true;

  ScreenTimeNotifier() : super(const ScreenTimeState()) {
    WidgetsBinding.instance.addObserver(this);
    _initScreenTime();
  }

  String get _todayKey {
    final now = DateTime.now();
    return 'cda_screentime_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _initScreenTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSeconds = prefs.getInt(_todayKey) ?? 0;
      final targetMins = prefs.getInt('cda_daily_target_minutes') ?? 60;

      // Load weekly array
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final List<int> weekMins = [];

      for (int i = 0; i < 7; i++) {
        final d = monday.add(Duration(days: i));
        final key = 'cda_screentime_${d.year}_${d.month.toString().padLeft(2, '0')}_${d.day.toString().padLeft(2, '0')}';
        final secs = prefs.getInt(key) ?? 0;
        weekMins.add((secs / 60).floor());
      }

      state = state.copyWith(
        todayActiveSeconds: savedSeconds,
        dailyTargetMinutes: targetMins,
        weeklyMinutes: weekMins,
      );

      _startActiveTicker();
      _startPeriodicDbFlush();
    } catch (_) {
      _startActiveTicker();
    }
  }

  void _startActiveTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isInForeground) return;

      final newSeconds = state.todayActiveSeconds + 1;
      state = state.copyWith(todayActiveSeconds: newSeconds);

      // Check 50% Milestone Notification
      if (!state.hasNotifiedHalfway && state.todayMinutes >= (state.dailyTargetMinutes / 2) && state.dailyTargetMinutes > 0) {
        state = state.copyWith(hasNotifiedHalfway: true);
        NotificationService().showNotification(
          id: 501,
          title: '🔥 Halfway to Daily Goal!',
          body: 'You have actively studied for ${state.formattedTodayTime} today. Keep the momentum going!',
        );
      }

      // Check 100% Goal Reached Milestone
      if (!state.hasNotifiedCompleted && state.isGoalCompleted) {
        state = state.copyWith(hasNotifiedCompleted: true);
        AppHaptics.heavyImpact();
        NotificationService().showNotification(
          id: 502,
          title: '🎯 Daily Study Goal Achieved!',
          body: 'Outstanding work! You completed your ${state.formattedTargetTime} learning target for today.',
        );
      }

      // Save to disk every 15 seconds
      if (newSeconds % 15 == 0) {
        _persistToLocalDisk();
      }
    });
  }

  void _startPeriodicDbFlush() {
    _dbFlushTimer?.cancel();
    // Flush cumulative hours to Supabase every 3 minutes
    _dbFlushTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _flushToSupabase();
    });
  }

  Future<void> _persistToLocalDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_todayKey, state.todayActiveSeconds);
      await prefs.setInt('cda_daily_target_minutes', state.dailyTargetMinutes);
    } catch (_) {}
  }

  Future<void> _flushToSupabase() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final hours = (state.todayActiveSeconds / 3600.0).round();
      if (hours <= 0) return;

      await SupabaseConfig.client.from('user_learning_goals').upsert({
        'user_id': user.id,
        'total_hours_learned': hours,
        'last_active_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Sets a customized daily target in minutes (e.g. 30m, 45m, 60m, 90m, 120m)
  Future<void> setDailyTargetMinutes(int minutes) async {
    state = state.copyWith(
      dailyTargetMinutes: minutes,
      hasNotifiedHalfway: false,
      hasNotifiedCompleted: state.todayMinutes >= minutes,
    );
    await _persistToLocalDisk();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isInForeground = true;
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      _isInForeground = false;
      _persistToLocalDisk();
      _flushToSupabase();
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    _dbFlushTimer?.cancel();
    _persistToLocalDisk();
    super.dispose();
  }
}

final screenTimeProvider = StateNotifierProvider<ScreenTimeNotifier, ScreenTimeState>((ref) {
  return ScreenTimeNotifier();
});

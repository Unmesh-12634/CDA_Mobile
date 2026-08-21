import 'dart:async';
import 'package:flutter/widgets.dart';
import '../config/supabase_config.dart';
import '../storage/local_cache_service.dart';

/// Real-time precision study time and screen tracker for CDA Career Companion.
/// Tracks exact foreground active seconds and syncs cumulative hours & minutes
/// to Local Storage and Supabase database.
class StudyTimeTrackerService with WidgetsBindingObserver {
  static final StudyTimeTrackerService _instance = StudyTimeTrackerService._internal();
  factory StudyTimeTrackerService() => _instance;
  StudyTimeTrackerService._internal();

  Timer? _tickerTimer;
  Timer? _periodicSyncTimer;
  DateTime? _sessionStartTime;
  int _uncommittedSeconds = 0;
  bool _isInitialized = false;

  /// Stream controller to notify UI of live study time updates
  final _studyTimeStreamController = StreamController<Duration>.broadcast();
  Stream<Duration> get onStudyTimeUpdated => _studyTimeStreamController.stream;

  /// Initializes lifecycle listener and active stopwatch
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _startSession();

    // Periodically flush uncommitted seconds to storage & Supabase every 60 seconds
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _flushTimeBuffer();
    });

    debugPrint('⏱️ [StudyTimeTrackerService] Initialized precision study timer.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSession();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pauseSessionAndFlush();
    }
  }

  void _startSession() {
    if (_sessionStartTime != null) return;
    _sessionStartTime = DateTime.now();

    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _uncommittedSeconds++;
      _studyTimeStreamController.add(Duration(seconds: getTotalActiveSeconds()));
    });
  }

  void _pauseSessionAndFlush() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _sessionStartTime = null;
    _flushTimeBuffer();
  }

  /// Flushes accumulated seconds into local storage and syncs to Supabase
  Future<void> _flushTimeBuffer() async {
    if (_uncommittedSeconds <= 0) return;

    final secondsToAdd = _uncommittedSeconds;
    _uncommittedSeconds = 0;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Update Local Storage
    final currentTotalSeconds = LocalCacheService().get<int>('cda_total_active_seconds') ?? 0;
    final newTotalSeconds = currentTotalSeconds + secondsToAdd;
    await LocalCacheService().set('cda_total_active_seconds', newTotalSeconds);

    final currentTodaySeconds = LocalCacheService().get<int>('cda_today_seconds_$todayStr') ?? 0;
    final newTodaySeconds = currentTodaySeconds + secondsToAdd;
    await LocalCacheService().set('cda_today_seconds_$todayStr', newTodaySeconds);

    final totalMinutes = (newTotalSeconds / 60).floor();
    await LocalCacheService().set('cda_total_study_minutes', totalMinutes);

    // 2. Sync to Supabase Database
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final cachedEmail = LocalCacheService().get<String>('cda_auth_email');
      final email = user?.email ?? cachedEmail ?? '';

      if (email.isNotEmpty) {
        final res = await SupabaseConfig.client
            .from('users')
            .select('total_study_minutes, total_active_seconds')
            .eq('email', email)
            .maybeSingle();

        final dbMinutes = res?['total_study_minutes'] as int? ?? 0;
        final dbSeconds = res?['total_active_seconds'] as int? ?? 0;

        // Take max of DB or local calculation to prevent rollback
        final syncMinutes = (dbMinutes + (secondsToAdd / 60).round()).clamp(totalMinutes, 999999);
        final syncSeconds = (dbSeconds + secondsToAdd).clamp(newTotalSeconds, 999999999);

        await SupabaseConfig.client.from('users').update({
          'total_study_minutes': syncMinutes,
          'total_active_seconds': syncSeconds,
          'last_seen_at': now.toIso8601String(),
        }).eq('email', email);

        debugPrint('⏱️ [StudyTimeTrackerService] Synced $secondsToAdd s to Supabase (Total: ${syncMinutes}m / ${(syncMinutes / 60).toStringAsFixed(1)}h).');
      }
    } catch (e) {
      debugPrint('⏱️ [StudyTimeTrackerService] Offline/Sync notice: $e');
    }
  }

  /// Manually record additional study duration (e.g. from quiz or AI interview session)
  Future<void> recordAdditionalStudyMinutes(int minutes) async {
    if (minutes <= 0) return;
    _uncommittedSeconds += (minutes * 60);
    await _flushTimeBuffer();
  }

  /// Returns total lifetime active seconds
  int getTotalActiveSeconds() {
    final localSec = LocalCacheService().get<int>('cda_total_active_seconds') ?? 0;
    return localSec + _uncommittedSeconds;
  }

  /// Returns total study hours as double (e.g. 3.5h)
  double getTotalStudyHours() {
    final totalSec = getTotalActiveSeconds();
    return totalSec / 3600.0;
  }

  /// Returns total study minutes
  int getTotalStudyMinutes() {
    final totalSec = getTotalActiveSeconds();
    return (totalSec / 60).floor();
  }

  /// Returns today's active study minutes
  int getTodayStudyMinutes() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todaySec = LocalCacheService().get<int>('cda_today_seconds_$todayStr') ?? 0;
    return ((todaySec + _uncommittedSeconds) / 60).floor();
  }

  /// Formatted study duration string e.g. "3h 45m" or "25m"
  String getFormattedTotalTime() {
    final totalMin = getTotalStudyMinutes();
    final hours = totalMin ~/ 60;
    final minutes = totalMin % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Clean disposal
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    _periodicSyncTimer?.cancel();
    _flushTimeBuffer();
    _studyTimeStreamController.close();
  }
}

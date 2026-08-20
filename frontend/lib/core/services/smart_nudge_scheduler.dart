import 'dart:math';
import 'package:flutter/foundation.dart';
import '../storage/local_cache_service.dart';
import 'dynamic_notification_engine.dart';
import 'notification_service.dart';

/// Smart Nudge Scheduler that evaluates user behavior and delivers dynamic, non-repetitive notifications
class SmartNudgeScheduler {
  static final SmartNudgeScheduler _instance = SmartNudgeScheduler._internal();
  factory SmartNudgeScheduler() => _instance;
  SmartNudgeScheduler._internal();

  static const String _lastNudgeTimeKey = 'cda_last_smart_nudge_timestamp';

  /// Evaluates student activity and triggers a dynamic contextual nudge if appropriate
  Future<void> evaluateAndTriggerNudge({
    required String studentName,
    required String targetRole,
    int streakDays = 1,
    double? lastInterviewScore,
    String? lastInterviewId,
    int? currentAtsScore,
    bool forceNudge = false,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastNudge = LocalCacheService().get<int>(_lastNudgeTimeKey) ?? 0;
      final hoursSinceLast = (now - lastNudge) / (1000 * 60 * 60);

      // Cooldown rule: At least 3 hours between dynamic smart nudges unless forced
      if (!forceNudge && hoursSinceLast < 3.0) {
        debugPrint('⏳ [SmartNudgeScheduler] In cooldown (${hoursSinceLast.toStringAsFixed(1)}h < 3.0h). Skipping auto-nudge.');
        return;
      }

      final rng = Random();
      final pickType = rng.nextInt(4);

      SmartNotificationPayload payload;

      if (lastInterviewScore != null && lastInterviewScore > 0 && rng.nextBool()) {
        // Nudge based on actual interview performance
        payload = DynamicNotificationEngine.generateInterviewFeedbackNudge(
          studentName: studentName,
          lastScore: lastInterviewScore,
          targetRole: targetRole,
          interviewId: lastInterviewId,
        );
      } else if (pickType == 0) {
        // Streak Nudge (Duolingo style)
        payload = DynamicNotificationEngine.generateStreakNudge(
          studentName: studentName,
          streakDays: streakDays > 0 ? streakDays : 1,
          targetRole: targetRole,
        );
      } else if (pickType == 1) {
        // Witty / Engagement Nudge (Zomato style)
        payload = DynamicNotificationEngine.generateWittyNudge(
          studentName: studentName,
          targetRole: targetRole,
        );
      } else if (pickType == 2) {
        // Resume ATS Nudge
        payload = DynamicNotificationEngine.generateResumeNudge(
          studentName: studentName,
          targetRole: targetRole,
          currentAtsScore: currentAtsScore,
        );
      } else {
        // Witty Nudge default
        payload = DynamicNotificationEngine.generateWittyNudge(
          studentName: studentName,
          targetRole: targetRole,
        );
      }

      await NotificationService().showSmartNotification(payload);
      await LocalCacheService().set(_lastNudgeTimeKey, now);
      debugPrint('🚀 [SmartNudgeScheduler] Dynamic Smart Nudge Dispatched: "${payload.title}"');
    } catch (e) {
      debugPrint('[SmartNudgeScheduler Error]: $e');
    }
  }

  /// Triggers an immediate test smart nudge (useful for verifying in-app)
  Future<void> triggerInstantTestNudge({
    required String studentName,
    required String targetRole,
  }) async {
    await evaluateAndTriggerNudge(
      studentName: studentName,
      targetRole: targetRole,
      forceNudge: true,
    );
  }
}

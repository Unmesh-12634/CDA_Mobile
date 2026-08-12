import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ActivityEventType {
  login,
  skillSelected,
  jobViewed,
  jobSaved,
  jobApplied,
  reelViewed,
  interviewStarted,
  interviewCompleted,
  courseOpened,
  lessonCompleted,
  quizCompleted,
}

class ActivityEvent {
  final String userId;
  final ActivityEventType eventType;
  final String? contentType;
  final String? contentId;
  final String? skillId;
  final int durationSeconds;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ActivityEvent({
    required this.userId,
    required this.eventType,
    this.contentType,
    this.contentId,
    this.skillId,
    this.durationSeconds = 0,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'event_type': eventType.name.toUpperCase(),
        'content_type': contentType,
        'content_id': contentId,
        'skill_id': skillId,
        'duration_seconds': durationSeconds,
        'metadata': metadata,
        'created_at': timestamp.toIso8601String(),
      };
}

class ActivityTrackerService {
  final List<ActivityEvent> _eventLog = [];

  void logEvent(ActivityEvent event) {
    _eventLog.add(event);
    debugPrint('📊 [ACTIVITY] ${event.eventType.name.toUpperCase()} - Content: ${event.contentType} (${event.durationSeconds}s)');
  }

  List<ActivityEvent> getEventLog() => List.unmodifiable(_eventLog);

  int getTotalStudySeconds() {
    return _eventLog
        .where((e) => e.eventType == ActivityEventType.lessonCompleted || e.eventType == ActivityEventType.reelViewed)
        .fold(0, (sum, e) => sum + e.durationSeconds);
  }
}

final activityTrackerProvider = Provider<ActivityTrackerService>((ref) {
  return ActivityTrackerService();
});

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'notification_service.dart';

/// Real-Time Bridge that listens to Supabase database events and triggers immediate phone notifications
class RealtimeNotificationBridge {
  static final RealtimeNotificationBridge _instance =
      RealtimeNotificationBridge._internal();
  factory RealtimeNotificationBridge() => _instance;
  RealtimeNotificationBridge._internal();

  RealtimeChannel? _notificationsChannel;
  String? _currentUserEmail;
  final Set<String> _processedIds = {};

  /// Starts listening to real-time database events for the authenticated student
  void startListening(String userEmail) {
    final cleanEmail = userEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;

    if (_currentUserEmail == cleanEmail && _notificationsChannel != null) {
      return; // Already listening for this user
    }

    stopListening();
    _currentUserEmail = cleanEmail;

    try {
      final client = SupabaseConfig.client;
      debugPrint('⚡ [RealtimeNotificationBridge] Connecting stream for $cleanEmail...');

      _notificationsChannel = client
          .channel('public:notifications:user:$cleanEmail')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_email',
              value: cleanEmail,
            ),
            callback: (payload) {
              _handleNewNotification(payload.newRecord);
            },
          )
          .subscribe();

      debugPrint('✅ [RealtimeNotificationBridge] Real-time notification channel active.');
    } catch (e) {
      debugPrint('❌ [RealtimeNotificationBridge Error]: $e');
    }
  }

  void _handleNewNotification(Map<String, dynamic> record) {
    try {
      final id = record['id']?.toString() ?? '';
      if (id.isNotEmpty && _processedIds.contains(id)) {
        return; // Skip duplicates
      }
      if (id.isNotEmpty) _processedIds.add(id);

      final title = record['title']?.toString() ?? 'Cranes Varsity Alert';
      final body = record['message']?.toString() ?? record['body']?.toString() ?? 'You have a new update in CDA.';
      final targetRoute = record['route']?.toString() ?? record['action_url']?.toString() ?? '/notifications';

      debugPrint('⚡ [RealtimeNotificationBridge] Received live DB event: "$title" ➔ Triggering Heads-up Notification');

      NotificationService().showNotification(
        id: id.hashCode,
        title: title,
        body: body,
        payload: targetRoute,
        channelId: 'cda_realtime_events',
        channelName: 'CDA Live Updates & Events',
      );
    } catch (e) {
      debugPrint('[RealtimeNotificationBridge Parse Error]: $e');
    }
  }

  /// Stops stream when user logs out
  void stopListening() {
    if (_notificationsChannel != null) {
      try {
        SupabaseConfig.client.removeChannel(_notificationsChannel!);
      } catch (_) {}
      _notificationsChannel = null;
    }
    _currentUserEmail = null;
    _processedIds.clear();
  }
}

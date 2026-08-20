import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dynamic_notification_engine.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Broadcast stream for handling notification tap navigation across the app
  final StreamController<String> _payloadController = StreamController<String>.broadcast();
  Stream<String> get onNotificationTapped => _payloadController.stream;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          debugPrint('🔔 [NotificationService] Notification clicked with payload: $payload');
          if (payload != null && payload.isNotEmpty) {
            _payloadController.add(payload);
          }
        },
      );

      // Request notification permissions for Android 13+ (API 33+)
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized successfully!');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  NotificationDetails _getChannelDetails({
    String channelId = 'cda_realtime_events',
    String channelName = 'CDA Live Updates & Events',
    String channelDescription = 'Real-time notifications for placement drives, AI interviews, and learning feeds',
    Importance importance = Importance.max,
    Priority priority = Priority.high,
  }) {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      ticker: 'CDA Notification',
      styleInformation: const BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Displays an instant heads-up notification on the user's phone
  Future<void> showNotification({
    int id = 100,
    required String title,
    required String body,
    String? payload,
    String channelId = 'cda_realtime_events',
    String channelName = 'CDA Live Updates & Events',
  }) async {
    try {
      if (!_isInitialized) await init();
      final details = _getChannelDetails(
        channelId: channelId,
        channelName: channelName,
      );
      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      debugPrint('🔔 Phone notification dispatched: "$title" (Route: $payload)');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Displays a dynamically computed smart notification (Zomato/Duolingo style)
  Future<void> showSmartNotification(SmartNotificationPayload payload, {int? id}) async {
    final notifId = id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await showNotification(
      id: notifId,
      title: payload.title,
      body: payload.body,
      payload: payload.payloadRoute,
      channelId: 'cda_smart_nudges',
      channelName: 'CDA AI Study & Placement Nudges',
    );
  }

  /// Instant notification when upgraded to CDA Pro
  Future<void> showProActivatedNotification(String planName, DateTime expiry) async {
    final expFormatted = '${expiry.day}/${expiry.month}/${expiry.year} ${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}';
    await showNotification(
      id: 201,
      title: '👑 $planName Activated!',
      body: 'Your CDA Pro pass is live until $expFormatted. Enjoy unlimited AI Mock Interviews and priority recruiter placement!',
      payload: '/profile',
    );
  }

  /// Notification when CDA Pro is expiring soon
  Future<void> showProExpiringSoonNotification(String planName, String timeRemaining) async {
    await showNotification(
      id: 202,
      title: '⚠️ CDA Pro Ending in $timeRemaining',
      body: 'Your "$planName" will expire soon. Tap to renew now and continue unlimited practice without interruption.',
      payload: '/profile',
    );
  }

  /// Notification when CDA Pro has expired
  Future<void> showProExpiredNotification(String planName) async {
    await showNotification(
      id: 203,
      title: '⚠️ CDA Pro Pass Expired',
      body: 'Your $planName period has ended. Renew anytime to restore unlimited AI interviews and Pro badge.',
      payload: '/profile',
    );
  }

  /// Real heads-up push notification sent on app launch & login (like WhatsApp/Instagram)
  Future<void> showAppLaunchSubscriptionAlert({
    required bool isPro,
    String? planName,
    DateTime? expiryDate,
    int trialsRemaining = 5,
  }) async {
    if (isPro && expiryDate != null) {
      final now = DateTime.now();
      final diff = expiryDate.difference(now);
      if (diff.isNegative) {
        await showProExpiredNotification(planName ?? 'CDA Pro');
        return;
      }

      String timeRemaining;
      if (diff.inDays > 0) {
        timeRemaining = '${diff.inDays} days ${diff.inHours % 24} hours left';
      } else if (diff.inHours > 0) {
        timeRemaining = '${diff.inHours} hours ${diff.inMinutes % 60} mins left';
      } else {
        timeRemaining = '${diff.inMinutes} minutes left';
      }

      final expFormatted = '${expiryDate.day}/${expiryDate.month}/${expiryDate.year} ${expiryDate.hour.toString().padLeft(2, '0')}:${expiryDate.minute.toString().padLeft(2, '0')}';

      await showNotification(
        id: 777,
        title: '👑 CDA Pro Active • $timeRemaining',
        body: 'Your "${planName ?? 'CDA Pro'}" is active until $expFormatted. Unlimited AI mock interviews unlocked!',
        payload: '/profile',
      );
    } else {
      // Free Tier Student Alert
      await showNotification(
        id: 888,
        title: '🚀 Upgrade to CDA Pro ($trialsRemaining Free Trials Left)',
        body: '⚡ Unlock unlimited AI mock interviews & FAANG placement passes starting at ₹9! Tap to explore Pro plans.',
        payload: '/profile',
      );
    }
  }
}


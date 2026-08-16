import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

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
          debugPrint('Notification clicked with payload: ${response.payload}');
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
    String channelId = 'cda_pro_channel',
    String channelName = 'CDA Pro & Career Alerts',
    String channelDescription = 'Notifications for CDA Pro membership and career updates',
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
  }) async {
    try {
      if (!_isInitialized) await init();
      final details = _getChannelDetails();
      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      debugPrint('🔔 Phone notification dispatched: "$title"');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Instant notification when upgraded to CDA Pro
  Future<void> showProActivatedNotification(String planName, DateTime expiry) async {
    final expFormatted = '${expiry.day}/${expiry.month}/${expiry.year} ${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}';
    await showNotification(
      id: 201,
      title: '👑 $planName Activated!',
      body: 'Your CDA Pro pass is live until $expFormatted. Enjoy unlimited AI Mock Interviews and priority recruiter placement!',
      payload: 'subscription_active',
    );
  }

  /// Notification when CDA Pro is expiring soon
  Future<void> showProExpiringSoonNotification(String planName, String timeRemaining) async {
    await showNotification(
      id: 202,
      title: '⚠️ CDA Pro Ending in $timeRemaining',
      body: 'Your "$planName" will expire soon. Tap to renew now and continue unlimited practice without interruption.',
      payload: 'subscription_expiring',
    );
  }

  /// Notification when CDA Pro has expired
  Future<void> showProExpiredNotification(String planName) async {
    await showNotification(
      id: 203,
      title: '⚠️ CDA Pro Pass Expired',
      body: 'Your $planName period has ended. Renew anytime to restore unlimited AI interviews and Pro badge.',
      payload: 'subscription_expired',
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
        payload: 'subscription_details',
      );
    } else {
      // Free Tier Student Alert
      await showNotification(
        id: 888,
        title: '🚀 Upgrade to CDA Pro ($trialsRemaining Free Trials Left)',
        body: '⚡ Unlock unlimited AI mock interviews & FAANG placement passes starting at ₹9! Tap to explore Pro plans.',
        payload: 'open_paywall',
      );
    }
  }
}

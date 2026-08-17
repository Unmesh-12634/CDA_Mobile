import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/network/java_api_service.dart';
import '../../auth/data/auth_provider.dart';
import '../../profile/data/user_profile_provider.dart';

class NotificationItem {
  final String id;
  final String userEmail;
  final String title;
  final String message;
  final String type; // INTERVIEWS, JOBS, SYSTEM, PROFILE
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.message,
    required this.type,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      userEmail: userEmail,
      title: title,
      message: message,
      type: type,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id']?.toString() ?? '',
      userEmail: map['user_email']?.toString() ?? map['userEmail']?.toString() ?? '',
      title: map['title']?.toString() ?? 'CDA Notification',
      message: map['message']?.toString() ?? map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'SYSTEM',
      actionUrl: map['action_url']?.toString() ?? map['actionUrl']?.toString(),
      isRead: map['is_read'] == true || map['isRead'] == true || map['read'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  final Ref ref;
  NotificationsNotifier(this.ref) : super([]) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final profile = ref.read(userProfileProvider);
    final email = profile.email.isNotEmpty ? profile.email : ref.read(authProvider).email;
    if (email.isEmpty) return;

    // 1. Try Java Backend
    try {
      final javaList = await JavaApiService.fetchNotifications(email: email);
      if (javaList != null && javaList.isNotEmpty) {
        state = javaList.map((m) => NotificationItem.fromMap(m)).toList();
        return;
      }
    } catch (e) {
      debugPrint('Java backend notifications notice: $e');
    }

    // 2. Direct Supabase DB Fallback
    try {
      final res = await SupabaseConfig.client
          .from('notifications')
          .select('*')
          .eq('user_email', email)
          .order('created_at', ascending: false);

      if (res.isNotEmpty) {
        state = res.map((m) => NotificationItem.fromMap(Map<String, dynamic>.from(m))).toList();
        return;
      }
    } catch (e) {
      debugPrint('Supabase notifications notice: $e');
    }

    // Fallback seed if table is new
    if (state.isEmpty) {
      state = [
        NotificationItem(
          id: 'notif-seed-1',
          userEmail: email,
          title: 'Welcome to CDA Student Pro 🚀',
          message: 'Your profile is ready. Explore AI Mock Interviews, Video Reels, and live job openings.',
          type: 'SYSTEM',
          actionUrl: '/profile',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
    }
  }

  Future<void> markAsRead(String id) async {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];

    try {
      await JavaApiService.markNotificationAsRead(id);
      await SupabaseConfig.client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    state = [for (final n in state) n.copyWith(isRead: true)];

    final profile = ref.read(userProfileProvider);
    final email = profile.email.isNotEmpty ? profile.email : ref.read(authProvider).email;
    if (email.isEmpty) return;

    try {
      await JavaApiService.markAllNotificationsAsRead(email: email);
      await SupabaseConfig.client.from('notifications').update({'is_read': true}).eq('user_email', email);
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    state = state.where((n) => n.id != id).toList();

    try {
      await JavaApiService.deleteNotification(id);
      await SupabaseConfig.client.from('notifications').delete().eq('id', id);
    } catch (_) {}
  }

  Future<void> createNotification({
    required String title,
    required String message,
    String type = 'SYSTEM',
    String? actionUrl,
  }) async {
    final profile = ref.read(userProfileProvider);
    final email = profile.email.isNotEmpty ? profile.email : ref.read(authProvider).email;
    if (email.isEmpty) return;

    final newNotif = NotificationItem(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userEmail: email,
      title: title,
      message: message,
      type: type,
      actionUrl: actionUrl,
      isRead: false,
      createdAt: DateTime.now(),
    );

    state = [newNotif, ...state];

    try {
      await JavaApiService.createNotification(
        email: email,
        title: title,
        message: message,
        type: type,
        actionUrl: actionUrl ?? '',
      );
      await SupabaseConfig.client.from('notifications').insert({
        'user_email': email,
        'title': title,
        'message': message,
        'type': type,
        'action_url': actionUrl,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>((ref) {
  return NotificationsNotifier(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider);
  return list.where((n) => !n.isRead).length;
});

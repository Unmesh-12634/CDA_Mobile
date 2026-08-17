import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/java_api_service.dart';
import '../../../../core/config/supabase_config.dart';

class UserActivityItem {
  final String id;
  final String title;
  final String sub;
  final IconData icon;
  final Color color;
  final String? route;
  final DateTime createdAt;

  const UserActivityItem({
    required this.id,
    required this.title,
    required this.sub,
    required this.icon,
    required this.color,
    this.route,
    required this.createdAt,
  });
}

final userActivitiesProvider = FutureProvider.family<List<UserActivityItem>, String>((ref, email) async {
  final targetEmail = email.isNotEmpty ? email : '';
  if (targetEmail.isEmpty) return [];
  
  // 1. Try Java Backend
  try {
    final javaList = await JavaApiService.fetchUserActivities(email: targetEmail);
    if (javaList != null && javaList.isNotEmpty) {
      return javaList.map((item) {
        final iconType = item['icon_type']?.toString().toLowerCase() ?? 'work';
        IconData icon;
        Color color;

        switch (iconType) {
          case 'interview':
            icon = Icons.psychology_rounded;
            color = const Color(0xFF6366F1);
            break;
          case 'play':
            icon = Icons.play_circle_fill_rounded;
            color = const Color(0xFF0EA5E9);
            break;
          case 'quiz':
            icon = Icons.bolt_rounded;
            color = const Color(0xFFF59E0B);
            break;
          case 'profile':
            icon = Icons.person_rounded;
            color = const Color(0xFF10B981);
            break;
          case 'work':
          default:
            icon = Icons.work_rounded;
            color = const Color(0xFF10B981);
            break;
        }

        DateTime dt;
        try {
          dt = DateTime.parse(item['created_at']?.toString() ?? '');
        } catch (_) {
          dt = DateTime.now();
        }

        return UserActivityItem(
          id: item['id']?.toString() ?? UniqueKey().toString(),
          title: item['title']?.toString() ?? 'Activity',
          sub: item['subtitle']?.toString() ?? '',
          icon: icon,
          color: color,
          route: item['route']?.toString(),
          createdAt: dt,
        );
      }).toList();
    }
  } catch (e) {
    debugPrint('Java activities provider fallback: $e');
  }

  // 2. Direct Supabase Query Fallback
  final items = <UserActivityItem>[];
  try {
    // Applications
    final appsRes = await SupabaseConfig.client
        .from('job_applications')
        .select('id, job_id, status, applied_at, updated_at')
        .eq('user_email', targetEmail)
        .order('applied_at', ascending: false)
        .limit(5);

    for (final a in (appsRes as List)) {
      DateTime dt;
      try {
        dt = DateTime.parse((a['applied_at'] ?? a['updated_at'])?.toString() ?? '');
      } catch (_) {
        dt = DateTime.now();
      }
      items.add(UserActivityItem(
        id: a['id']?.toString() ?? '',
        title: 'Job Application Submitted',
        sub: 'Status: ${a['status'] ?? 'Applied'}',
        icon: Icons.work_rounded,
        color: const Color(0xFF10B981),
        route: '/application-tracker',
        createdAt: dt,
      ));
    }


    // Interview reports
    final repRes = await SupabaseConfig.client
        .from('ai_interview_reports')
        .select('id, target_role, overall_score, created_at')
        .eq('candidate_email', targetEmail)
        .order('created_at', ascending: false)
        .limit(5);

    for (final r in (repRes as List)) {
      DateTime dt;
      try {
        dt = DateTime.parse(r['created_at']?.toString() ?? '');
      } catch (_) {
        dt = DateTime.now();
      }
      final score = (r['overall_score'] as num?)?.toDouble() ?? 0.0;
      items.add(UserActivityItem(
        id: r['id']?.toString() ?? '',
        title: 'Completed ${r['target_role'] ?? 'Technical'} Mock',
        sub: 'Overall Score: ${score.toInt()}%',
        icon: Icons.psychology_rounded,
        color: const Color(0xFF6366F1),
        route: '/interview/reports',
        createdAt: dt,
      ));
    }
  } catch (e) {
    debugPrint('Supabase direct activity fallback error: $e');
  }

  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
});

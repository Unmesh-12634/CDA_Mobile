import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeTab = 'All';

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'notif-1',
      'title': 'AI Interview Report Ready 🎯',
      'body': 'Your recent Spring Boot mock interview analysis is complete. Overall Score: 88%.',
      'time': '10 mins ago',
      'category': 'Interviews',
      'isUnread': true,
      'icon': Icons.insights_rounded,
      'color': const Color(0xFF6366F1),
      'route': '/interview/analysis/rep-101',
    },
    {
      'id': 'notif-2',
      'title': 'Job Application Shortlisted! 🚀',
      'body': 'Google India reviewed your profile for Senior Java Engineer and scheduled a technical round.',
      'time': '2 hours ago',
      'category': 'Jobs',
      'isUnread': true,
      'icon': Icons.work_rounded,
      'color': const Color(0xFF10B981),
      'route': '/applications',
    },
    {
      'id': 'notif-3',
      'title': 'Daily Quiz Streak Maintained 🔥',
      'body': 'You completed today\'s 5 Java questions and earned +200 XP. 4-day streak active!',
      'time': '5 hours ago',
      'category': 'System',
      'isUnread': false,
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFF59E0B),
      'route': '/quiz',
    },
    {
      'id': 'notif-4',
      'title': 'New Course Unlocked in Roadmap 📚',
      'body': 'Spring Boot Microservices & Docker containerization phase is now accessible.',
      'time': 'Yesterday',
      'category': 'System',
      'isUnread': false,
      'icon': Icons.school_rounded,
      'color': const Color(0xFF0EA5E9),
      'route': '/learn',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _activeTab == 'All'
        ? _notifications
        : _notifications.where((n) => n['category'] == _activeTab).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.credDarkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.onSurface, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notification Center',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['isUnread'] = false;
                }
              });
            },
            child: const Text('Mark all read',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Category Selector Tabs
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ['All', 'Interviews', 'Jobs', 'System'].map((cat) {
                final isSelected = _activeTab == cat;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.credDarkCard : Colors.white),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Notifications List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      'No notifications found.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, i) {
                      final item = filteredList[i];
                      final isUnread = item['isUnread'] as bool;
                      final color = item['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          setState(() => item['isUnread'] = false);
                          if (item['route'] != null) {
                            context.push(item['route'] as String);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? (isDark
                                    ? color.withValues(alpha: 0.12)
                                    : color.withValues(alpha: 0.05))
                                : (isDark ? AppColors.credDarkCard : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isUnread
                                  ? color.withValues(alpha: 0.4)
                                  : (isDark
                                      ? AppColors.credDarkBorder
                                      : const Color(0xFFEEF0F2)),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon container
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item['icon'] as IconData,
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 14),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isUnread
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['body'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['time'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

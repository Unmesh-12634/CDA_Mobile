import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class ApplicationTrackerScreen extends StatefulWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  State<ApplicationTrackerScreen> createState() => _ApplicationTrackerScreenState();
}

class _ApplicationTrackerScreenState extends State<ApplicationTrackerScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _applications = [
    {
      'id': 'app-101',
      'title': 'Senior Java Backend Engineer',
      'company': 'Google India',
      'logoText': 'G',
      'logoBg': const Color(0xFF4285F4),
      'location': 'Bengaluru, KA (Hybrid)',
      'salary': '₹24 - 36 LPA',
      'appliedDate': 'Applied 3 days ago',
      'status': 'Interviewing',
      'statusColor': const Color(0xFF6366F1),
      'nextStep': 'AI Technical Round • Aug 8, 2026',
    },
    {
      'id': 'app-102',
      'title': 'Flutter Mobile App Developer',
      'company': 'Cred',
      'logoText': 'C',
      'logoBg': const Color(0xFF10B981),
      'location': 'Bengaluru (Remote)',
      'salary': '₹18 - 28 LPA',
      'appliedDate': 'Applied 1 week ago',
      'status': 'Under Review',
      'statusColor': const Color(0xFFF59E0B),
      'nextStep': 'Resume shortlisted by recruiter',
    },
    {
      'id': 'app-103',
      'title': 'Full Stack Engineer (Node + React)',
      'company': 'Microsoft',
      'logoText': 'M',
      'logoBg': const Color(0xFF0EA5E9),
      'location': 'Hyderabad, TS',
      'salary': '₹22 - 32 LPA',
      'appliedDate': 'Applied 2 weeks ago',
      'status': 'Offered',
      'statusColor': const Color(0xFF10B981),
      'nextStep': 'Offer Letter Received 🎉',
    },
    {
      'id': 'app-104',
      'title': 'AI Machine Learning Trainee',
      'company': 'Amazon AWS',
      'logoText': 'A',
      'logoBg': const Color(0xFFFF9900),
      'location': 'Bengaluru, KA',
      'salary': '₹15 - 22 LPA',
      'appliedDate': 'Applied yesterday',
      'status': 'Applied',
      'statusColor': const Color(0xFF94A3B8),
      'nextStep': 'Application submitted successfully',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _selectedFilter == 'All'
        ? _applications
        : _applications.where((a) => a['status'] == _selectedFilter).toList();

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
          'Active Applications Tracker',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Filter Tabs
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ['All', 'Interviewing', 'Under Review', 'Offered', 'Applied'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
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
                        filter,
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

          // Applications List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      'No applications in this category.',
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
                      final app = filteredList[i];
                      final statusColor = app['statusColor'] as Color;
                      final logoBg = app['logoBg'] as Color;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.credDarkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Logo Avatar
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: logoBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      app['logoText'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Title & Company
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app['title'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${app['company']} • ${app['location']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    app['status'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(
                                height: 1,
                                color: isDark
                                    ? AppColors.credDarkBorder
                                    : const Color(0xFFF0F2F4)),
                            const SizedBox(height: 12),

                            // Next Step Banner
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 15, color: statusColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    app['nextStep'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      side: BorderSide(
                                        color: isDark
                                            ? AppColors.credDarkBorder
                                            : const Color(0xFFCBD5E1),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: () => context.push('/jobs/job-101'),
                                    child: Text(
                                      'View Job',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: () => context.push('/interview/setup'),
                                    child: const Text(
                                      'Prepare AI Interview',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

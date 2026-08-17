import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/jobs_repository.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../profile/data/user_profile_provider.dart';

class ApplicationTrackerScreen extends ConsumerStatefulWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  ConsumerState<ApplicationTrackerScreen> createState() => _ApplicationTrackerScreenState();
}

class _ApplicationTrackerScreenState extends ConsumerState<ApplicationTrackerScreen> {
  String _selectedFilter = 'All';

  final List<String> _statusOptions = [
    'Applied',
    'Under Review',
    'Interviewing',
    'Offered',
    'Accepted',
    'Rejected',
    'Withdrawn',
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return const Color(0xFF0EA5E9);
      case 'under review':
        return const Color(0xFFF59E0B);
      case 'interviewing':
        return const Color(0xFF8B5CF6);
      case 'offered':
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'withdrawn':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  Future<void> _updateStatus(String appId, String newStatus) async {
    final success = await ref.read(jobsRepositoryProvider).updateApplicationStatus(
          applicationId: appId,
          newStatus: newStatus,
        );

    if (success && mounted) {
      ref.invalidate(userApplicationsProvider(null));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Application status updated to "$newStatus"!', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final userEmail = profile.email.isNotEmpty ? profile.email : ref.watch(authProvider).email;
    final appsAsync = ref.watch(userApplicationsProvider(userEmail));

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh DB Status',
            onPressed: () => ref.invalidate(userApplicationsProvider(userEmail)),
          ),
        ],
      ),
      body: appsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Failed to load applications: $err', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        ),
        data: (applications) {
          final filteredList = _selectedFilter == 'All'
              ? applications
              : applications.where((a) => a['status'].toString().toLowerCase() == _selectedFilter.toLowerCase()).toList();

          return Column(
            children: [
              const SizedBox(height: 16),
              // Filter Tabs
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: ['All', 'Applied', 'Under Review', 'Interviewing', 'Offered', 'Rejected'].map((filter) {
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 54, color: isDark ? const Color(0xFF475569) : AppColors.outline),
                            const SizedBox(height: 12),
                            Text(
                              applications.isEmpty ? 'No applications submitted yet.' : 'No applications matching "$_selectedFilter"',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.search_rounded, size: 16),
                              label: const Text('Browse Jobs & Apply Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(userApplicationsProvider(userEmail)),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredList.length,
                          itemBuilder: (context, i) {
                            final app = filteredList[i];
                            final status = app['status']?.toString() ?? 'Applied';
                            final statusColor = _getStatusColor(status);

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
                                          color: statusColor.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: Text(
                                            app['logoText'] as String? ?? 'JO',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 17,
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
                                              app['title'] as String? ?? 'Software Role',
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
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Interactive Status Dropdown Bar
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.sync_alt_rounded, size: 16, color: statusColor),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Application Status:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white70 : AppColors.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _statusOptions.contains(status) ? status : 'Applied',
                                            dropdownColor: isDark ? AppColors.credDarkCard : Colors.white,
                                            icon: Icon(Icons.arrow_drop_down_rounded, color: statusColor),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w900,
                                              color: statusColor,
                                            ),
                                            onChanged: (newStatus) {
                                              if (newStatus != null && newStatus != status) {
                                                _updateStatus(app['id'].toString(), newStatus);
                                              }
                                            },
                                            items: _statusOptions.map((opt) {
                                              return DropdownMenuItem<String>(
                                                value: opt,
                                                child: Text(opt),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Applied Date
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        app['appliedDate'] as String? ?? 'Recently applied',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                                        ),
                                      ),
                                      Text(
                                        app['salary'] as String? ?? '',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
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
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/mock_jobs.dart';
import '../../data/saved_jobs_provider.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _hasApplied = false;

  void _applyWithProfile(Job job) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingLg),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Apply to ${job.company}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : AppColors.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: isDark ? const Color(0xFF334155) : AppColors.surfaceContainer),
                const SizedBox(height: 12),
                Text(
                  'Profile Data Auto-Fetched',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileRow(context, Icons.person_rounded, 'Full Name', 'Arjun Verma'),
                const SizedBox(height: 8),
                _buildProfileRow(
                    context, Icons.email_rounded, 'Email', 'arjun.verma@example.com'),
                const SizedBox(height: 8),
                _buildProfileRow(
                    context, Icons.description_rounded, 'Resume', 'Arjun_Verma_Resume_2025.pdf'),
                const SizedBox(height: 8),
                _buildProfileRow(
                    context, Icons.workspace_premium_rounded, 'Match Score', '${job.matchScore}% Profile Match'),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Submit Application Now',
                  icon: Icons.send_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _hasApplied = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Application submitted successfully to ${job.company}!'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.outline)),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = sampleJobs.firstWhere(
      (j) => j.id == widget.jobId,
      orElse: () => sampleJobs.first,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Job Details',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isSaved = ref.watch(savedJobsProvider).contains(job.id);
              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? AppColors.primary : (isDark ? Colors.white : AppColors.onSurface),
                ),
                onPressed: () {
                  ref.read(savedJobsProvider.notifier).toggleSave(job.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSaved ? 'Removed from saved jobs' : 'Job saved to your bookmarks!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Banner Card
            GlassCard(
              padding: const EdgeInsets.all(AppConstants.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            job.logoText,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.company,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${job.matchScore}% Match',
                          style: AppTypography.codeMono.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF0F2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: isDark ? const Color(0xFF94A3B8) : AppColors.outline),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job.location,
                          style: TextStyle(
                              fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.attach_money_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        job.salary,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success),
                      ),
                      const Spacer(),
                      Text(
                        job.postedAgo,
                        style: TextStyle(
                            fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.stackLg),

            // Job Description
            Text(
              'Job Overview',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurfaceVariant,
                height: 1.5,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: AppConstants.stackLg),

            // Key Responsibilities
            Text(
              'Key Responsibilities',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: job.responsibilities.map((resp) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4, right: 8),
                        child: Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: AppColors.primary),
                      ),
                      Expanded(
                        child: Text(
                          resp,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? Colors.white70 : AppColors.onSurface,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppConstants.stackLg),

            // Qualifications
            Text(
              'Requirements & Skills',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: job.requirements.map((req) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4, right: 8),
                        child: Icon(Icons.star_outline_rounded,
                            size: 16, color: AppColors.tertiary),
                      ),
                      Expanded(
                        child: Text(
                          req,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? Colors.white70 : AppColors.onSurface,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppConstants.stackLg),

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.surfaceContainerHigh),
                  ),
                  child: Text(
                    '# $tag',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.psychology_rounded,
                    color: AppColors.primary),
                label: Text(
                  'Practice AI Interview for ${job.company}',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                onPressed: () => context.push('/interview/setup'),
              ),
              const SizedBox(height: 10),
              GradientButton(
                text: _hasApplied ? 'Applied ✓' : 'Apply Now with Profile',
                icon: _hasApplied
                    ? Icons.check_circle_rounded
                    : Icons.send_rounded,
                onPressed:
                    _hasApplied ? null : () => _applyWithProfile(job),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

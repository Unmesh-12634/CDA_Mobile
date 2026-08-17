import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../profile/data/user_profile_provider.dart';
import '../../../home/data/weekly_goal_provider.dart';
import '../../data/jobs_repository.dart';
import '../../data/mock_jobs.dart';
import '../../data/saved_jobs_provider.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _localApplied = false;

  void _applyWithProfile(Job job, String realEmail) {
    final userProfile = ref.read(userProfileProvider);
    final authState = ref.read(authProvider);

    final realName = userProfile.name.isNotEmpty
        ? userProfile.name
        : (authState.fullName.isNotEmpty ? authState.fullName : 'Arjun Verma');
    final displayEmail = realEmail;
    final realResume = userProfile.resumeFileName ?? (userProfile.resumeUrl != null ? 'Profile_Resume.pdf' : 'No Resume Uploaded');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apply with CDA Profile',
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
              Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Text(
                'Profile Data Auto-Fetched from Database',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              _buildProfileRow(context, Icons.person_rounded, 'Full Name', realName),
              const SizedBox(height: 8),
              _buildProfileRow(context, Icons.email_rounded, 'Email', displayEmail),
              const SizedBox(height: 8),
              _buildProfileRow(context, Icons.description_rounded, 'Resume', realResume),
              const SizedBox(height: 8),
              _buildProfileRow(
                  context, Icons.workspace_premium_rounded, 'Match Score', '${job.matchScore}% Profile Match'),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Submit Application Now',
                icon: Icons.send_rounded,
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _localApplied = true);

                  final messenger = ScaffoldMessenger.of(context);
                  final repo = ref.read(jobsRepositoryProvider);
                  await repo.applyForJob(
                    jobId: job.id,
                    userEmail: displayEmail,
                    resumeUrl: userProfile.resumeUrl ?? userProfile.resumeFilePath,
                  );

                  ref.invalidate(userApplicationsProvider(displayEmail));
                  ref.invalidate(appliedJobIdsProvider(displayEmail));

                  // Complete today's daily career mission!
                  ref.read(weeklyGoalProvider.notifier).completeToday();

                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Application submitted successfully to ${job.company}!')),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.onSurface)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final userEmail = profile.email.isNotEmpty ? profile.email : ref.watch(authProvider).email;

    final jobsAsync = ref.watch(realJobsListProvider(null));
    final allJobs = jobsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => sampleJobs,
    );

    final job = allJobs.firstWhere(
      (j) => j.id == widget.jobId,
      orElse: () => Job(
        id: widget.jobId,
        title: 'Software Developer',
        company: 'Tech Partner',
        location: 'Remote',
        type: 'Full-time',
        salary: '\$120,000 / yr',
        logoText: 'TP',
        category: 'Engineering',
        matchScore: 92,
        postedAgo: 'Recently posted',
        experienceLevel: 'Mid-Senior',
        description: 'Exciting role building modern apps.',
        responsibilities: const ['Build clean components', 'Deliver scalable software'],
        requirements: const ['Strong CS fundamentals', 'Experience with Flutter/Dart'],
        tags: const ['Flutter', 'Dart', 'Remote'],
      ),
    );

    final appliedIdsAsync = ref.watch(appliedJobIdsProvider(userEmail));
    final appliedSet = appliedIdsAsync.maybeWhen(
      data: (set) => set,
      orElse: () => <String>{},
    );

    final isApplied = _localApplied || appliedSet.contains(job.id);
    final isSaved = ref.watch(savedJobsProvider).contains(job.id);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: isSaved ? AppColors.primary : (isDark ? Colors.white70 : AppColors.onSurface),
            ),
            onPressed: () => ref.read(savedJobsProvider.notifier).toggleSave(job.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        job.logoText,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    job.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${job.company} • ${job.location}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Applied to this Position ✓',
                            style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Job Overview Grid Card
            GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailMetaItem(context, 'Salary', job.salary, Icons.payments_outlined, isDark),
                  Container(height: 30, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  _buildDetailMetaItem(context, 'Job Type', job.type, Icons.work_outline_rounded, isDark),
                  Container(height: 30, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  _buildDetailMetaItem(context, 'Category', job.category, Icons.category_outlined, isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text('About the Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.onSurface)),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Key Requirements
            Text('Key Skills & Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.onSurface)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
      bottomSheet: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GradientButton(
              text: isApplied ? 'Applied ✓ — Update Status in Tracker' : 'Apply Now with Profile',
              icon: isApplied ? Icons.assignment_outlined : Icons.send_rounded,
              onPressed: isApplied
                  ? () => context.push('/application-tracker')
                  : () => _applyWithProfile(job, userEmail),
            ),
          ),
      ),
    ),
    );
  }

  Widget _buildDetailMetaItem(BuildContext context, String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.onSurface)),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF64748B) : AppColors.outline)),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/user_profile_provider.dart';
import '../../../subscription/data/subscription_provider.dart';
import '../../../subscription/presentation/widgets/cda_paywall_sheet.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../jobs/data/saved_jobs_provider.dart';
import '../../../learn/data/saved_reels_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _completedInterviewsCount = 0;
  int _avgInterviewScore = 0;
  List<Map<String, dynamic>> _recentInterviews = [];
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _loadLiveDatabaseMetrics();
  }

  Future<void> _loadLiveDatabaseMetrics() async {
    final profile = ref.read(userProfileProvider);
    final userEmail = profile.email.isNotEmpty ? profile.email : 'unii12634@gmail.com';

    // Refresh real-time saved items
    ref.read(savedJobsProvider.notifier).loadSavedJobs();
    ref.read(savedReelsProvider.notifier).loadSavedReels();

    try {
      // 1. Fetch AI Interview Reports from database
      final reports = await SupabaseConfig.client
          .from('ai_interview_reports')
          .select('id, target_role, overall_score, created_at')
          .eq('user_email', userEmail)
          .order('created_at', ascending: false)
          .limit(5);

      int totalScore = 0;
      final interviewList = <Map<String, dynamic>>[];
      if (reports.isNotEmpty) {
        for (final r in reports) {
          final score = (r['overall_score'] as num?)?.toInt() ?? 85;
          totalScore += score;
          interviewList.add({
            'id': r['id']?.toString() ?? '',
            'role': r['target_role']?.toString() ?? 'AI Mock Interview',
            'score': '$score/100',
            'badge': score >= 90 ? 'Top 5%' : (score >= 75 ? 'Pass' : 'Practice'),
            'badgeColor': score >= 90
                ? const Color(0xFF0EA5E9)
                : (score >= 75 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
            'date': _formatTimestamp(r['created_at']?.toString()),
          });
        }
      }

      if (mounted) {
        setState(() {
          _completedInterviewsCount = reports.length;
          _avgInterviewScore = reports.isNotEmpty ? (totalScore ~/ reports.length) : 0;
          _recentInterviews = interviewList;
          _isLoadingMetrics = false;
        });
      }
    } catch (e) {
      debugPrint('Live metrics load notice: $e');
      if (mounted) setState(() => _isLoadingMetrics = false);
    }
  }

  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Recent';
    }
  }

  void _showEditProfileModal(BuildContext context) {
    context.push('/edit-profile').then((_) {
      _loadLiveDatabaseMetrics();
    });
  }

  Future<void> _openExternalLink(BuildContext context, String rawUrl, String platform) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No $platform link added yet.'),
          action: SnackBarAction(
            label: 'Add Now',
            textColor: AppColors.primary,
            onPressed: () => _showEditProfileModal(context),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String formattedUrl = trimmed;
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    try {
      final uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $platform link ($formattedUrl)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddSkillDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.credDarkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add New Skill',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Docker, GraphQL, Spring Boot',
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF64748B) : AppColors.outline,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final skill = controller.text.trim();
              if (skill.isNotEmpty) {
                ref.read(userProfileProvider.notifier).addSkill(skill);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added skill "$skill"'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final savedJobs = ref.watch(savedJobsProvider);
    final savedReels = ref.watch(savedReelsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final liveSavedJobsCount = savedJobs.length;
    final liveSavedReelsCount = savedReels.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.credDarkBase : Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'My Profile',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Icon(
                themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 19,
                color: themeMode == ThemeMode.dark ? const Color(0xFFF59E0B) : AppColors.primary,
              ),
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Icon(
                Icons.settings_outlined,
                size: 19,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(userProfileProvider.notifier).refreshProfileFromDb();
            await _loadLiveDatabaseMetrics();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.marginMobile,
              vertical: AppConstants.stackMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Profile Card
                _buildHeroCard(context, profile, isDark),

                const SizedBox(height: 18),

                // 2. Profile Strength & Completeness Bar (100% Real Dynamic)
                _buildCompletionCard(context, profile, isDark),

                const SizedBox(height: 16),

                // 3. Pro Membership Banner
                _buildProMembershipCard(context, ref, isDark),

                const SizedBox(height: 16),

                // 4. Resume & ATS Portfolio Card
                _buildResumeCard(context, profile, isDark),

                const SizedBox(height: 16),

                // 5. Social & Portfolio Branded Interactive Icons
                _buildSocialLinksCard(context, profile, isDark),

                const SizedBox(height: 24),

                // 6. Live Performance & Analytics Grid
                _buildSectionHeader(context, 'PERFORMANCE & ANALYTICS', isDark),
                const SizedBox(height: 12),
                _buildStatisticsGrid(
                  context,
                  isDark,
                  savedJobsCount: liveSavedJobsCount,
                  savedReelsCount: liveSavedReelsCount,
                ),

                const SizedBox(height: 24),

                // 7. Live Recent AI Mock Interview Reports
                _buildRecentInterviewHistory(context, isDark),

                const SizedBox(height: 24),

                // 8. Core Skills & Expertise
                _buildSkillsSection(context, profile, isDark),

                const SizedBox(height: 24),

                // 9. AI Career Domain Match (Real Top 5 Fields)
                _buildDomainReadinessSection(context, profile, isDark),

                const SizedBox(height: 24),

                // 10. Account & Preferences Grouped Card (Exact 5 items)
                _buildSectionHeader(context, 'ACCOUNT & PREFERENCES', isDark),
                const SizedBox(height: 12),
                _buildAccountSettingsCard(
                  context,
                  ref,
                  profile,
                  isDark,
                  savedJobsCount: liveSavedJobsCount,
                  savedReelsCount: liveSavedReelsCount,
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Safe Avatar Builder ────────────────────────────────────────────────────
  Widget _buildAvatarWidget(UserProfile profile, bool isDark) {
    final imagePath = profile.avatarImagePath?.trim();
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            imagePath,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildAvatarFallback(profile.avatarInitials, isDark),
          ),
        );
      } else if (!kIsWeb) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            return ClipOval(
              child: Image.file(
                file,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(profile.avatarInitials, isDark),
              ),
            );
          }
        } catch (_) {}
      }
    }

    return _buildAvatarFallback(profile.avatarInitials, isDark);
  }

  Widget _buildAvatarFallback(String initials, bool isDark) {
    final displayInitials = initials.trim().isNotEmpty ? initials.trim().toUpperCase() : 'UN';
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
              : const [Color(0xFF0284C7), Color(0xFF0369A1)],
        ),
      ),
      child: Center(
        child: Text(
          displayInitials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ── Hero Card ──────────────────────────────────────────────────────────────
  Widget _buildHeroCard(BuildContext context, UserProfile profile, bool isDark) {
    final sub = ref.watch(subscriptionProvider);
    final isPro = sub.isPremium;
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isPro
        ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
        : (isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0));

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: isPro ? 1.6 : 1.2),
        boxShadow: [
          BoxShadow(
            color: isPro
                ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                : (isDark
                    ? const Color(0xFF4648D4).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.05)),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // VIP Golden Frame Avatar Container
              Stack(
                alignment: Alignment.bottomRight,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isPro
                          ? const SweepGradient(
                              colors: [
                                Color(0xFFFFDF00),
                                Color(0xFFD4AF37),
                                Color(0xFFF59E0B),
                                Color(0xFFFFE57F),
                                Color(0xFFFFDF00),
                              ],
                            )
                          : AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: isPro
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.50)
                              : AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: isPro ? 22 : 18,
                          spreadRadius: isPro ? 2 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.credDarkCard : Colors.white,
                        border: Border.all(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: _buildAvatarWidget(profile, isDark),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                        gradient: isPro
                            ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1C2541) : Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isPro
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                : Colors.transparent,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPro ? Icons.workspace_premium_rounded : Icons.check,
                        size: isPro ? 13 : 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name.isNotEmpty ? profile.name : 'Unmesh Learner',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              color: isDark ? Colors.white : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showEditProfileModal(context),
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, size: 15, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.targetRole.isNotEmpty ? profile.targetRole : 'Full Stack Engineer & AI Specialist',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.email.isNotEmpty ? profile.email : 'unii12634@gmail.com',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (profile.college.isNotEmpty) ...[
                  _buildProfileBadgePill(
                    icon: Icons.school_rounded,
                    label: profile.college,
                    color: const Color(0xFF0EA5E9),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                ],
                if (profile.experienceYears > 0) ...[
                  _buildProfileBadgePill(
                    icon: Icons.work_history_rounded,
                    label: '${profile.experienceYears.toStringAsFixed(1)} Yrs Exp',
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                ],
                _buildProfileBadgePill(
                  icon: (profile.resumeFileName != null || profile.resumeUrl != null)
                      ? Icons.description_rounded
                      : Icons.file_upload_outlined,
                  label: (profile.resumeFileName != null || profile.resumeUrl != null)
                      ? 'Resume Verified'
                      : 'Upload Resume',
                  color: (profile.resumeFileName != null || profile.resumeUrl != null)
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBadgePill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Profile Strength & Completeness Bar (100% Real Dynamic) ─────────────
  Widget _buildCompletionCard(BuildContext context, UserProfile profile, bool isDark) {
    final double progress = profile.profileStrengthPercentage;
    final int percent = (progress * 100).toInt();

    final Color badgeColor = percent >= 90
        ? const Color(0xFF10B981)
        : (percent >= 60 ? const Color(0xFF0EA5E9) : const Color(0xFFF59E0B));

    return InkWell(
      onTap: () => _showProfileStrengthChecklistModal(context, profile),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.credDarkSurface : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.credDarkBorder : const Color(0xFFC7D2FE),
          ),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.military_tech_rounded, color: badgeColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Profile Strength',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent% Complete',
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.info_outline_rounded, size: 13, color: badgeColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    profile.profileStrengthMissingHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      percent >= 100 ? 'View Details' : 'Improve (+)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: badgeColor),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileStrengthChecklistModal(BuildContext context, UserProfile profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cleanPhone = profile.phone.replaceAll(RegExp(r'\D'), '');
    final hasPhone = cleanPhone.length >= 10;
    final hasResume = (profile.resumeFileName != null && profile.resumeFileName!.trim().isNotEmpty) ||
        (profile.resumeUrl != null && profile.resumeUrl!.trim().isNotEmpty) ||
        (profile.resumeFilePath != null && profile.resumeFilePath!.trim().isNotEmpty) ||
        profile.isCvVerified;
    final hasRole = profile.targetRole.trim().isNotEmpty;
    final hasAcademics = profile.college.trim().isNotEmpty && profile.degree.trim().isNotEmpty;
    final hasSkills = profile.skills.length >= 3;
    final hasSocial = profile.githubUrl.trim().isNotEmpty || profile.linkedinUrl.trim().isNotEmpty || profile.portfolioUrl.trim().isNotEmpty;
    final hasPhoto = profile.avatarImagePath != null && profile.avatarImagePath!.isNotEmpty;
    final int percent = (profile.profileStrengthPercentage * 100).toInt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Profile Strength: $percent%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (percent >= 90)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ALL-STAR 🌟',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'Complete all sections for 4.5x faster recruiter shortlisting',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildChecklistItem(
                    title: 'Resume & ATS CV Upload',
                    desc: hasResume ? 'Resume verified & active' : 'Upload PDF/Doc for instant ATS scan (+20%)',
                    isDone: hasResume,
                    weight: '+20%',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditProfileModal(context);
                    },
                  ),
                  _buildChecklistItem(
                    title: 'Target Career Role & CTC',
                    desc: hasRole ? '${profile.targetRole} (${profile.targetAnnualPackage})' : 'Define target domain & expected package (+15%)',
                    isDone: hasRole,
                    weight: '+15%',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditProfileModal(context);
                    },
                  ),
                  _buildChecklistItem(
                    title: 'Academics & College',
                    desc: hasAcademics ? '${profile.college} • ${profile.degree}' : 'Add your college, degree, and branch (+15%)',
                    isDone: hasAcademics,
                    weight: '+15%',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditProfileModal(context);
                    },
                  ),
                  _buildChecklistItem(
                    title: 'Core Technical Skills',
                    desc: hasSkills ? '${profile.skills.length} skills listed' : 'Add at least 3 skills to show competency (+10%)',
                    isDone: hasSkills,
                    weight: '+10%',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddSkillDialog(context, ref);
                    },
                  ),
                  _buildChecklistItem(
                    title: 'Portfolio & Professional Socials',
                    desc: hasSocial ? 'GitHub / LinkedIn connected' : 'Link your GitHub or LinkedIn profile (+10%)',
                    isDone: hasSocial,
                    weight: '+10%',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditProfileModal(context);
                    },
                  ),
                  _buildChecklistItem(
                    title: 'Contact Phone Number',
                    desc: hasPhone ? profile.phone : 'Add verified mobile number for recruiter calls (+10%)',
                    isDone: hasPhone,
                    weight: '+10%',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditProfileModal(context);
                    },
                  ),
                  _buildChecklistItem(
                    title: 'Profile Picture / Avatar',
                    desc: hasPhoto ? 'Custom photo uploaded' : 'Upload professional headshot (+10%)',
                    isDone: hasPhoto,
                    weight: '+10%',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditProfileModal(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String desc,
    required bool isDone,
    required String weight,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isDone ? const Color(0xFF10B981) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                weight,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDone ? const Color(0xFF10B981) : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          desc,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          isDone ? Icons.done_all_rounded : Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isDone ? const Color(0xFF10B981) : AppColors.primary,
        ),
      ),
    );
  }


  // ── Pro Membership Card ─────────────────────────────────────────────────────
  Widget _buildProMembershipCard(BuildContext context, WidgetRef ref, bool isDark) {
    final sub = ref.watch(subscriptionProvider);
    if (sub.isPremium) {
      final Duration diff = sub.expiryDate != null
          ? sub.expiryDate!.difference(DateTime.now())
          : Duration.zero;

      final String timeLabel = diff.isNegative
          ? 'Expired'
          : diff.inDays > 0
              ? '${diff.inDays} days remaining'
              : '${diff.inHours}h ${diff.inMinutes % 60}m remaining';

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sub.planName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                        ),
                        child: Text(
                          timeLabel,
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Unlimited AI Mock Interviews & Priority Placement',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'UPGRADE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Standard Access Plan',
                style: TextStyle(
                  color: Color(0xFFE0E7FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Become a CDA Pro Member ⚡',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Get unlimited AI mock interviews & real-time voice evaluation starting at ₹299/mo.',
            style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => CDAPaywallSheet.show(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Upgrade to Pro (from ₹299/mo) 👑',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resume Card ────────────────────────────────────────────────────────────
  Widget _buildResumeCard(BuildContext context, UserProfile profile, bool isDark) {
    final hasResume = (profile.resumeFileName != null && profile.resumeFileName!.isNotEmpty) ||
                      (profile.resumeUrl != null && profile.resumeUrl!.isNotEmpty);
    final resumeDisplayName = (profile.resumeFileName != null && profile.resumeFileName!.isNotEmpty)
        ? profile.resumeFileName!
        : (profile.resumeUrl != null && profile.resumeUrl!.isNotEmpty
            ? profile.resumeUrl!.split('/').last
            : 'Upload PDF or DOC for AI Matching');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.credDarkCard : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.35 : 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0EA5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasResume ? 'Resume Verified' : 'No Resume Uploaded',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                      Text(
                        resumeDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showEditProfileModal(context),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                hasResume ? 'Edit' : 'Upload',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Social & Portfolio Branded Interactive Logo Icons ───────────────────
  Widget _buildSocialLinksCard(BuildContext context, UserProfile profile, bool isDark) {
    final hasGithub = profile.githubUrl.trim().isNotEmpty;
    final hasLinkedin = profile.linkedinUrl.trim().isNotEmpty;
    final hasPortfolio = profile.portfolioUrl.trim().isNotEmpty;
    final hasAnySocial = hasGithub || hasLinkedin || hasPortfolio;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.credDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Social & Professional Profiles',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
              InkWell(
                onTap: () => _showEditProfileModal(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 17,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasAnySocial) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  if (hasGithub) ...[
                    _buildSocialLogoButton(
                      context: context,
                      icon: Icons.code_rounded,
                      label: 'GitHub',
                      url: profile.githubUrl,
                      bgColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF24292E),
                      iconColor: Colors.white,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (hasLinkedin) ...[
                    _buildSocialLogoButton(
                      context: context,
                      icon: Icons.link_rounded,
                      label: 'LinkedIn',
                      url: profile.linkedinUrl,
                      bgColor: const Color(0xFF0A66C2),
                      iconColor: Colors.white,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (hasPortfolio) ...[
                    _buildSocialLogoButton(
                      context: context,
                      icon: Icons.language_rounded,
                      label: 'Portfolio',
                      url: profile.portfolioUrl,
                      bgColor: const Color(0xFF10B981),
                      iconColor: Colors.white,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                  ],
                  InkWell(
                    onTap: () => _showEditProfileModal(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'No social links added yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showEditProfileModal(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Profiles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialLogoButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String url,
    required Color bgColor,
    required Color iconColor,
    required bool isDark,
  }) {
    return Tooltip(
      message: 'Open $label ($url)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openExternalLink(context, url, label),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_outward_rounded, color: Colors.white70, size: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 6. Live Performance & Analytics Grid ───────────────────────────────────
  Widget _buildStatisticsGrid(
    BuildContext context,
    bool isDark, {
    required int savedJobsCount,
    required int savedReelsCount,
  }) {
    if (_isLoadingMetrics) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'COMPLETED MOCKS',
                value: '$_completedInterviewsCount',
                trend: _completedInterviewsCount > 0 ? 'Live database sync' : 'Start your first mock',
                icon: Icons.assignment_turned_in_rounded,
                accentColor: AppColors.primary,
                isDark: isDark,
                onTap: () => context.push('/interview/setup'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'AVG MOCK SCORE',
                value: _avgInterviewScore > 0 ? '$_avgInterviewScore/100' : 'N/A',
                trend: _avgInterviewScore >= 85 ? 'Top percentile' : 'Keep practicing',
                icon: Icons.analytics_rounded,
                accentColor: const Color(0xFF0EA5E9),
                isDark: isDark,
                onTap: () => context.push('/interview/setup'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'SAVED JOBS',
                value: '$savedJobsCount',
                trend: 'Bookmark library',
                icon: Icons.bookmark_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => context.push('/saved-jobs'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'SAVED REELS',
                value: '$savedReelsCount',
                trend: 'Learning feed',
                icon: Icons.play_circle_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => context.go('/learn'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: isDark ? const Color(0xFF64748B) : AppColors.outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.displayMobile.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.codeMono.copyWith(
              fontSize: 9.5,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trend,
            style: TextStyle(
              fontSize: 10.5,
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── 7. Live Recent AI Mock Interview Reports ───────────────────────────────
  Widget _buildRecentInterviewHistory(BuildContext context, bool isDark) {
    if (_recentInterviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'AI MOCK INTERVIEW HISTORY', isDark),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(18),
            onTap: () => context.push('/interview/setup'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start your first AI Mock Interview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Practice real questions with instant voice feedback',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, 'RECENT AI MOCK INTERVIEWS', isDark),
            TextButton(
              onPressed: () => context.push('/interview/history'),
              child: const Text(
                'View All',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentInterviews.map((rep) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GlassCard(
              onTap: () => context.push('/interview/analysis/${rep['id']}'),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rep['role'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rep['date'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (rep['badgeColor'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (rep['badgeColor'] as Color).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${rep['score']} • ${rep['badge']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rep['badgeColor'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── 8. Core Skills Section ─────────────────────────────────────────────────
  Widget _buildSkillsSection(BuildContext context, UserProfile profile, bool isDark) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Core Skills & Expertise',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                tooltip: 'Add Skill',
                onPressed: () => _showAddSkillDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...profile.skills.map((skill) {
                return _buildSkillChip(context, skill, isDark);
              }),
              InkWell(
                onTap: () => _showAddSkillDialog(context, ref),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Add Skill',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, String skill, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: TextStyle(
              color: isDark ? const Color(0xFFF1F5F9) : AppColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => ref.read(userProfileProvider.notifier).removeSkill(skill),
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }

  // ── 9. AI Domain Readiness Section (Real Top 5 Fields) ─────────────────────
  Widget _buildDomainReadinessSection(BuildContext context, UserProfile profile, bool isDark) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.explore_rounded, color: Color(0xFF0EA5E9), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Career Domain Match',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...profile.domainScores.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildAnimatedDomainBar(context, e.key, e.value, isDark),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnimatedDomainBar(BuildContext context, String label, double value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutQuad,
          tween: Tween<double>(begin: 0, end: value),
          builder: (context, animValue, _) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: animValue,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  // ── 10. Account & Settings Grouped Card (Exact 5 items) ───────────────────
  Widget _buildAccountSettingsCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool isDark, {
    required int savedJobsCount,
    required int savedReelsCount,
  }) {
    final sub = ref.watch(subscriptionProvider);
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          // 1. Edit Profile
          _buildSettingsTile(
            context,
            icon: Icons.edit_note_rounded,
            title: 'Edit Profile',
            subtitle: 'Update name, college, role, skills, links',
            isDark: isDark,
            onTap: () => _showEditProfileModal(context),
          ),
          const Divider(height: 1, color: Colors.white10),
          // 2. Saved Jobs
          _buildSettingsTile(
            context,
            icon: Icons.bookmark_rounded,
            title: 'Saved Jobs',
            subtitle: '$savedJobsCount bookmarked opportunities',
            isDark: isDark,
            iconColor: const Color(0xFFF59E0B),
            onTap: () => context.push('/saved-jobs'),
          ),
          const Divider(height: 1, color: Colors.white10),
          // 3. Saved Reels
          _buildSettingsTile(
            context,
            icon: Icons.play_circle_rounded,
            title: 'Saved Reels',
            subtitle: '$savedReelsCount saved learning videos',
            isDark: isDark,
            iconColor: const Color(0xFF10B981),
            onTap: () => context.go('/learn'),
          ),
          const Divider(height: 1, color: Colors.white10),
          // 4. Upgrade CDA Pro
          _buildSettingsTile(
            context,
            icon: Icons.workspace_premium_rounded,
            title: sub.isPremium ? 'CDA Pro Membership Active' : 'Upgrade CDA Pro',
            subtitle: sub.isPremium ? 'Active subscription • Manage plan' : 'Unlimited AI Mock Interviews starting at ₹299/mo',
            isDark: isDark,
            iconColor: const Color(0xFFF59E0B),
            onTap: () => CDAPaywallSheet.show(context),
          ),
          const Divider(height: 1, color: Colors.white10),
          // 5. Sign Out
          _buildSettingsTile(
            context,
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Safely disconnect this device',
            isDark: isDark,
            iconColor: const Color(0xFFEF4444),
            textColor: const Color(0xFFEF4444),
            onTap: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          color: textColor ?? (isDark ? Colors.white : AppColors.onSurface),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark ? const Color(0xFF64748B) : AppColors.outline,
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.credDarkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/user_profile_provider.dart';
import '../../../rewards/data/rewards_provider.dart';
import '../../../rewards/presentation/widgets/reward_celebration_dialog.dart';
import '../../../subscription/data/subscription_provider.dart';
import '../../../subscription/presentation/widgets/cda_paywall_sheet.dart';
import '../../../auth/data/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileModal(BuildContext context, WidgetRef ref, UserProfile profile) {
    context.push('/edit-profile');
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.surface.withValues(alpha: 0.9),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'My Profile',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_outlined,
                size: 20,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.marginMobile,
            vertical: AppConstants.stackMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Hero Profile Banner
              _buildHeroCard(context, ref, profile, isDark),

              const SizedBox(height: 20),

              // Profile Completion Tracker Card
              _buildCompletionCard(context, ref, profile, isDark),

              const SizedBox(height: 16),

              // ── PRO MEMBERSHIP BANNER / CARD ────────────────────────────
              Consumer(
                builder: (context, ref, _) {
                  final sub = ref.watch(subscriptionProvider);
                  if (sub.isPremium) {
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
                            child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CDA Pro Membership Active 👑',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Unlimited AI Mock Interviews & Priority Placement',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 11),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'UPGRADE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${sub.trialsRemaining}/${sub.totalFreeTrials} Free Trials Remaining',
                              style: const TextStyle(
                                  color: Color(0xFFE0E7FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Become a CDA Pro Member ⚡',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Get unlimited AI mock interviews & real-time voice evaluation starting at ₹299/mo.',
                          style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => CDAPaywallSheet.show(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Upgrade to Pro (from ₹299/mo) 👑',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // CDA Rewards & Coins Card (CRED-style)
              Consumer(
                builder: (context, ref, _) {
                  final rewards = ref.watch(rewardsProvider);
                  final isDk = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDk ? const Color(0xFF151D30) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: isDk ? 0.25 : 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                          blurRadius: 20,
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.credGoldGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), blurRadius: 10)],
                                  ),
                                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${rewards.coinBalance} CDA Coins',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: isDk ? Colors.white : AppColors.onSurface),
                                    ),
                                    Text('Level ${rewards.level} • ${rewards.levelTitle}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => showRewardCelebrationDialog(context, coinsEarned: 50, rewardTitle: 'Profile Achievement Bonus'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(gradient: AppColors.credGoldGradient, borderRadius: BorderRadius.circular(100)),
                                child: const Text('Claim', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...rewards.transactions.take(3).map((tx) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 15),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDk ? Colors.white : AppColors.onSurface)),
                                    Text(tx.timestamp, style: TextStyle(fontSize: 10, color: isDk ? const Color(0xFF94A3B8) : AppColors.outline)),
                                  ],
                                ),
                              ),
                              Text('+${tx.coins}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF10B981))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              _buildSectionHeader(context, 'PERFORMANCE & ANALYTICS'),
              const SizedBox(height: 12),
              _buildStatisticsGrid(context, isDark),

              const SizedBox(height: 24),

              // Core Competencies & Skills Section
              _buildSkillsSection(context, ref, profile, isDark),

              const SizedBox(height: 24),

              // AI Domain Readiness Section
              _buildDomainReadinessSection(context, profile, isDark),

              const SizedBox(height: 24),

              // Achievements & Certifications Section
              _buildAchievementsSection(context, isDark),

              const SizedBox(height: 24),

              // Account & Preferences Section
              _buildSectionHeader(context, 'ACCOUNT & PREFERENCES'),
              const SizedBox(height: 12),
              _buildAccountSettingsCard(context, ref, profile, isDark),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // Hero Card with Avatar & Badges
  Widget _buildHeroCard(BuildContext context, WidgetRef ref, UserProfile profile, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Glow Avatar with Verified Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      border: Border.all(
                        color: isDark ? const Color(0xFF38BDF8) : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: profile.avatarImagePath != null
                        ? ClipOval(
                            child: kIsWeb
                                ? Image.network(
                                    profile.avatarImagePath!,
                                    width: 78,
                                    height: 78,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(profile.avatarImagePath!),
                                    width: 78,
                                    height: 78,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Center(
                            child: Text(
                              profile.avatarInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // User Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              color: isDark ? Colors.white : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                              const SizedBox(width: 6),
                        Consumer(
                          builder: (context, ref, _) {
                            final sub = ref.watch(subscriptionProvider);
                            if (sub.isPremium) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium_rounded,
                                        color: Colors.white, size: 12),
                                    SizedBox(width: 3),
                                    Text(
                                      'PRO 👑',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.degree} • ${profile.college}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.center_focus_strong_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.targetRole,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          // Horizontal Quick Badges Track
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildProfileBadgePill(
                  icon: Icons.local_fire_department_rounded,
                  label: '${profile.streakDays} Day Streak',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                if (profile.isCvVerified) ...[
                  _buildProfileBadgePill(
                    icon: Icons.verified_user_rounded,
                    label: 'CV Verified',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                ],
                _buildProfileBadgePill(
                  icon: Icons.star_rounded,
                  label: '${profile.cgpa}/10 CGPA',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildProfileBadgePill(
                  icon: Icons.auto_awesome_rounded,
                  label: '94% AI Match',
                  color: AppColors.secondary,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                Consumer(
                  builder: (context, ref, _) {
                    final rewards = ref.watch(rewardsProvider);
                    return GestureDetector(
                      onTap: () => showRewardCelebrationDialog(
                        context,
                        coinsEarned: 50,
                        rewardTitle: 'Profile Achievement Bonus',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.credGoldGradient,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${rewards.coinBalance} Coins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Profile Completeness Bar Widget
  Widget _buildCompletionCard(BuildContext context, WidgetRef ref, UserProfile profile, bool isDark) {
    const double progress = 0.88;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
        ),
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
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
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
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add portfolio links to hit 100%',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: () => _showEditProfileModal(context, ref, profile),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Complete Now',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
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

  // Statistics Grid (2x2)
  Widget _buildStatisticsGrid(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'COMPLETED JOBS',
                value: '24',
                trend: '+4 this month',
                icon: Icons.assignment_turned_in_rounded,
                accentColor: AppColors.primary,
                isDark: isDark,
                onTap: () => context.push('/interview/analysis/rep-101'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'INTERVIEW SCORE',
                value: '840',
                trend: 'Top 5% candidate',
                icon: Icons.analytics_rounded,
                accentColor: AppColors.secondary,
                isDark: isDark,
                onTap: () => context.push('/interview/analysis/rep-101'),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12, height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'SAVED JOBS',
                value: '12',
                trend: '3 closing soon',
                icon: Icons.bookmark_rounded,
                accentColor: AppColors.tertiary,
                isDark: isDark,
                onTap: () => context.push('/saved-jobs'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'SAVED REELS',
                value: '48',
                trend: 'Learning library',
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
              fontSize: 24,
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

  // Skills Section
  Widget _buildSkillsSection(BuildContext context, WidgetRef ref, UserProfile profile, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.skills.map((skill) {
              return _buildSkillChip(context, ref, skill, isDark);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, WidgetRef ref, String skill, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: isDark ? const Color(0xFFF1F5F9) : AppColors.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // AI Domain Readiness Section
  Widget _buildDomainReadinessSection(BuildContext context, UserProfile profile, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.explore_rounded, color: AppColors.secondary, size: 18),
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
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  // Achievements Section
  Widget _buildAchievementsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, 'ACHIEVEMENTS & CERTIFICATES'),
            TextButton(
              onPressed: () => showComingSoonSnackBar(context, 'All Certificates'),
              child: const Text(
                'View All',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAchievementTile(
          context,
          title: 'Full Stack Web Development',
          subtitle: 'Certified by Tech-Alpha Institute • 2023',
          icon: Icons.workspace_premium_rounded,
          iconColor: const Color(0xFFF59E0B),
          isDark: isDark,
          onTap: () => showComingSoonSnackBar(context, 'Certificate Details'),
        ),
        const SizedBox(height: 10),
        _buildAchievementTile(
          context,
          title: 'Top 10% Hackathon Winner',
          subtitle: 'Global Code Jam • Winter 2023',
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFF6366F1),
          isDark: isDark,
          onTap: () => showComingSoonSnackBar(context, 'Hackathon Details'),
        ),
      ],
    );
  }

  Widget _buildAchievementTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? const Color(0xFF64748B) : AppColors.outline,
          ),
        ],
      ),
    );
  }

  // Account & Settings Grouped Card
  Widget _buildAccountSettingsCard(BuildContext context, WidgetRef ref, UserProfile profile, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile Info',
            iconBgColor: AppColors.primary.withValues(alpha: 0.12),
            iconColor: AppColors.primary,
            onTap: () => _showEditProfileModal(context, ref, profile),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings & Preferences',
            iconBgColor: AppColors.secondary.withValues(alpha: 0.12),
            iconColor: AppColors.secondary,
            onTap: () => context.push('/settings'),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            iconBgColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            iconColor: isDark ? Colors.white70 : AppColors.onSurface,
            onTap: () => showComingSoonSnackBar(context, 'Help & Support'),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            iconBgColor: AppColors.errorContainer.withValues(alpha: 0.3),
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(
                    'Sign Out?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.onSurface),
                  ),
                  content: Text(
                    'Are you sure you want to sign out of your account?',
                    style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ref.read(authProvider.notifier).signOut();
                        Navigator.pop(ctx);
                        context.go('/login');
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTypography.codeMono.copyWith(
          color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconBgColor,
    required Color iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyleColor = titleColor ?? (isDark ? Colors.white : AppColors.onSurface);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: textStyleColor,
          fontSize: 14.5,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: titleColor ?? (isDark ? const Color(0xFF64748B) : AppColors.outline),
          ),
        ],
      ),
    );
  }
}

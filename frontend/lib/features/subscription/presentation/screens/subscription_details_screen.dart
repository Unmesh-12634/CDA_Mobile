import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/subscription_provider.dart';
import '../widgets/cda_paywall_sheet.dart';

class SubscriptionDetailsScreen extends ConsumerWidget {
  const SubscriptionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String expiryString = sub.expiryDate != null
        ? DateFormat('dd MMMM yyyy').format(sub.expiryDate!)
        : (sub.isPremium ? '08 September 2026' : 'N/A (Free Tier)');

    final int daysRemaining = sub.expiryDate != null
        ? sub.expiryDate!.difference(DateTime.now()).inDays.clamp(0, 365)
        : (sub.isPremium ? 30 : 0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.credDarkBase : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.onSurface,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Subscription & Benefits',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? const Color(0xFFF59E0B) : AppColors.primary,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
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
              // ── Active Plan Status Banner ──────────────────────────────────
              _buildStatusCard(context, ref, sub, expiryString, daysRemaining, isDark),

              const SizedBox(height: 20),

              // ── Subscription Details & Validity Grid ───────────────────────
              _buildSectionTitle(context, 'PLAN DETAILS & VALIDITY', isDark),
              const SizedBox(height: 10),
              _buildValidityInfoCard(context, sub, expiryString, daysRemaining, isDark),

              const SizedBox(height: 24),

              // ── Premium Unlocked Features & Perks ──────────────────────────
              _buildSectionTitle(context, 'UNLOCKED PREMIUM BENEFITS', isDark),
              const SizedBox(height: 10),
              _buildFeaturesGrid(context, sub, isDark),

              const SizedBox(height: 24),

              // ── Performance & Usage Stats ──────────────────────────────────
              _buildSectionTitle(context, 'USAGE & PRACTICE STATS', isDark),
              const SizedBox(height: 10),
              _buildUsageStatsCard(context, sub, isDark),

              const SizedBox(height: 24),

              // ── Plan Management Actions ────────────────────────────────────
              _buildSectionTitle(context, 'SUBSCRIPTION MANAGEMENT', isDark),
              const SizedBox(height: 10),
              _buildActionOptionsCard(context, ref, sub, isDark),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.codeMono.copyWith(
        color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Hero Active Status Card ────────────────────────────────────────────────
  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionState sub,
    String expiryString,
    int daysRemaining,
    bool isDark,
  ) {
    if (sub.isPremium) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E273A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.credGoldGradient,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'CDA PRO ACTIVE 👑',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981), width: 1),
                  ),
                  child: const Text(
                    'Auto-Renews',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              sub.planName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Billing Cycle: ${sub.billingCycle.toUpperCase()} • Unlimited Access',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.event_available_rounded, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Valid until: $expiryString',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Free Tier Status Banner
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'STANDARD ACCESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Upgrade to CDA Pro ⚡',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unlock unlimited AI mock interviews & real-time voice evaluation starting at ₹299/mo.',
            style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => CDAPaywallSheet.show(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66F59E0B),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Upgrade Now (from ₹299/mo) 👑',
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

  // ── Validity & Billing Info Card ───────────────────────────────────────────
  Widget _buildValidityInfoCard(
    BuildContext context,
    SubscriptionState sub,
    String expiryString,
    int daysRemaining,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            icon: Icons.card_membership_rounded,
            label: 'Current Plan',
            value: sub.planName,
            isDark: isDark,
          ),
          Divider(color: isDark ? AppColors.credDarkBorder : const Color(0xFFF1F5F9), height: 18),
          _buildInfoRow(
            context,
            icon: Icons.autorenew_rounded,
            label: 'Billing Cycle',
            value: sub.billingCycle == 'none' ? 'Free Access' : sub.billingCycle.toUpperCase(),
            isDark: isDark,
          ),
          Divider(color: isDark ? AppColors.credDarkBorder : const Color(0xFFF1F5F9), height: 18),
          _buildInfoRow(
            context,
            icon: Icons.calendar_today_rounded,
            label: 'Plan Validity',
            value: expiryString,
            isDark: isDark,
          ),
          if (sub.isPremium) ...[
            Divider(color: isDark ? AppColors.credDarkBorder : const Color(0xFFF1F5F9), height: 18),
            _buildInfoRow(
              context,
              icon: Icons.hourglass_top_rounded,
              label: 'Days Remaining',
              value: '$daysRemaining Days Left',
              valueColor: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: isDark ? const Color(0xFF94A3B8) : AppColors.outline),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: valueColor ?? (isDark ? Colors.white : AppColors.onSurface),
          ),
        ),
      ],
    );
  }

  // ── Features Checklist Grid ────────────────────────────────────────────────
  Widget _buildFeaturesGrid(BuildContext context, SubscriptionState sub, bool isDark) {
    final features = [
      {'title': 'Unlimited AI Mock Interviews', 'desc': 'Practice as many voice & technical rounds as you want.', 'active': true},
      {'title': 'Real-time Voice & Tone Feedback', 'desc': 'Instant metrics on pace, confidence, and articulation.', 'active': true},
      {'title': 'Priority Recruiter Placement', 'desc': 'Verified candidate profile pushed to top tech recruiters.', 'active': true},
      {'title': 'Verified CDA Pro Profile Badge', 'desc': 'Golden Pro badge displayed on your profile and resume.', 'active': true},
      {'title': 'ATS Resume Score & AI Parsing', 'desc': 'Unlimited resume uploads and key skill gap analysis.', 'active': true},
      {'title': 'Custom Career Domain Roadmaps', 'desc': 'Personalized track recommendations for AI, Backend & Mobile.', 'active': true},
    ];

    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: features.map((f) {
          final isActive = sub.isPremium || f['active'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                    color: isActive ? const Color(0xFF10B981) : Colors.grey,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f['desc'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Usage & Practice Stats Card ────────────────────────────────────────────
  Widget _buildUsageStatsCard(BuildContext context, SubscriptionState sub, bool isDark) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('INTERVIEWS', sub.isPremium ? 'Unlimited' : 'Standard', isDark),
          Container(width: 1, height: 36, color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
          _buildStatColumn('ATS REVIEW', sub.isPremium ? 'Active' : 'Basic', isDark),
          Container(width: 1, height: 36, color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
          _buildStatColumn('PLACEMENT', sub.isPremium ? 'Priority' : 'Standard', isDark),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Action Options Card ───────────────────────────────────────────────────
  Widget _buildActionOptionsCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionState sub,
    bool isDark,
  ) {
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
          _buildActionTile(
            context,
            icon: Icons.swap_horiz_rounded,
            title: sub.isPremium ? 'Change Billing Plan (Monthly/Yearly)' : 'Upgrade to Pro Member',
            iconColor: const Color(0xFFF59E0B),
            onTap: () => CDAPaywallSheet.show(context),
            isDark: isDark,
          ),
          Divider(color: isDark ? AppColors.credDarkBorder : const Color(0xFFF1F5F9), height: 1),
          _buildActionTile(
            context,
            icon: Icons.receipt_long_rounded,
            title: 'View Invoices & Payment Receipts',
            iconColor: const Color(0xFF0EA5E9),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Receipt downloaded for current billing period.'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            isDark: isDark,
          ),
          Divider(color: isDark ? AppColors.credDarkBorder : const Color(0xFFF1F5F9), height: 1),
          _buildActionTile(
            context,
            icon: Icons.restart_alt_rounded,
            title: 'Reset to Standard Access (Developer Test)',
            iconColor: const Color(0xFF6366F1),
            onTap: () {
              ref.read(subscriptionProvider.notifier).resetToStandard();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Subscription state reset to Standard Access!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: isDark ? const Color(0xFF64748B) : AppColors.outline,
      ),
    );
  }
}

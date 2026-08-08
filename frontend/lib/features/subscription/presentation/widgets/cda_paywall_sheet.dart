import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/cda_button.dart';
import '../../data/subscription_provider.dart';

class CDAPaywallSheet extends ConsumerStatefulWidget {
  const CDAPaywallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CDAPaywallSheet(),
    );
  }

  @override
  ConsumerState<CDAPaywallSheet> createState() => _CDAPaywallSheetState();
}

class _CDAPaywallSheetState extends ConsumerState<CDAPaywallSheet> {
  String _selectedPlan = 'yearly'; // 'yearly' | 'monthly'
  String _selectedPayment = 'upi'; // 'upi' | 'card' | 'netbanking'
  bool _isProcessing = false;

  void _processUpgrade() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Trigger state upgrade
    ref.read(subscriptionProvider.notifier).upgradeToPro(
          planId: _selectedPlan == 'yearly' ? 'pro_annual' : 'pro_monthly',
          billingCycle: _selectedPlan,
        );

    Navigator.of(context).pop();

    // Show celebration dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1422),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
        ),
        title: const Row(
          children: [
            Text('👑 ', style: TextStyle(fontSize: 24)),
            Text('Welcome to CDA Pro!',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your subscription is now active! You have unlocked:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            SizedBox(height: 12),
            _ProFeatureBullet(text: 'Unlimited AI Mock Interviews'),
            _ProFeatureBullet(text: 'Real-time Voice & Code Evaluation'),
            _ProFeatureBullet(text: 'Priority Placement on Recruiter Feeds'),
            _ProFeatureBullet(text: 'Verified CDA Pro Profile Badge'),
          ],
        ),
        actions: [
          CDAButton(
            label: 'Start Unlimited Practice 🚀',
            variant: CDAButtonVariant.gold,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF090D16) : Colors.white;
    final bottomInset = MediaQuery.of(context).padding.bottom + 36;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
            color: isDark ? const Color(0xFF1E2D4A) : Colors.transparent,
            width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'CDA PRO',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (!sub.isPremium)
                  Text(
                    '${sub.trialsRemaining}/${sub.totalFreeTrials} Free Trials Left',
                    style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Main Title
            Text(
              'Unlock Unlimited AI Mock Interviews',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.onSurface,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Get unlimited voice-guided technical & HR mock interviews with detailed scorecards.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Feature Grid / Checklist
            const Column(
              children: [
                _FeatureRow(
                    icon: Icons.mic_rounded,
                    title: 'Unlimited AI Voice Interviews',
                    desc: 'No trial limits. Practice as many sessions as you need.'),
                SizedBox(height: 10),
                _FeatureRow(
                    icon: Icons.analytics_rounded,
                    title: 'Detailed AI Scorecard & Tips',
                    desc: 'Granular evaluation of speech clarity, confidence & answer quality.'),
                SizedBox(height: 10),
                _FeatureRow(
                    icon: Icons.verified_user_rounded,
                    title: 'Verified Pro Badge on Profile',
                    desc: 'Stand out to top tech recruiters with a Pro verified profile.'),
              ],
            ),
            const SizedBox(height: 24),

            // Pricing Options Label
            Text(
              'SELECT MEMBERSHIP PLAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Pricing Cards Row (Rupees ₹)
            Row(
              children: [
                // Yearly Card (Save 45%)
                Expanded(
                  child: _PlanCard(
                    title: 'Annual Pro',
                    price: '₹1,999',
                    subtitle: '₹166/mo (Save 45%)',
                    badge: 'MOST POPULAR',
                    isSelected: _selectedPlan == 'yearly',
                    onTap: () => setState(() => _selectedPlan = 'yearly'),
                  ),
                ),
                const SizedBox(width: 12),
                // Monthly Card
                Expanded(
                  child: _PlanCard(
                    title: 'Monthly Pro',
                    price: '₹299',
                    subtitle: 'Billed monthly',
                    badge: null,
                    isSelected: _selectedPlan == 'monthly',
                    onTap: () => setState(() => _selectedPlan = 'monthly'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Payment Methods
            Text(
              'PAYMENT METHOD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _PaymentChip(
                  label: 'UPI / GPay / PhonePe',
                  icon: Icons.account_balance_wallet_rounded,
                  isSelected: _selectedPayment == 'upi',
                  onTap: () => setState(() => _selectedPayment = 'upi'),
                ),
                const SizedBox(width: 8),
                _PaymentChip(
                  label: 'Cards / NetBanking',
                  icon: Icons.credit_card_rounded,
                  isSelected: _selectedPayment == 'card',
                  onTap: () => setState(() => _selectedPayment = 'card'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action CTA Button
            _isProcessing
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                : CDAButton(
                    label: _selectedPlan == 'yearly'
                        ? 'Pay ₹1,999 & Become a Pro ⚡'
                        : 'Pay ₹299 & Become a Pro ⚡',
                    variant: CDAButtonVariant.gold,
                    onTap: _processUpgrade,
                  ),
            const SizedBox(height: 12),

            Center(
              child: Text(
                '🔒 100% Secure Checkout • Cancel Anytime',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureRow(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFF59E0B), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEFF6FF))
              : (isDark ? const Color(0xFF121B2D) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : (isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? const Color(0xFFF59E0B)
                    : (isDark ? const Color(0xFF64748B) : AppColors.outline),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEFF6FF))
                : (isDark ? const Color(0xFF121B2D) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : (isDark ? const Color(0xFF64748B) : AppColors.outline)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProFeatureBullet extends StatelessWidget {
  final String text;
  const _ProFeatureBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

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
  String _selectedPlan = '1_month'; // '1_hour' | '1_day' | '1_month' | '3_months' | '1_year'
  String _selectedPayment = 'upi'; // 'upi' | 'card' | 'netbanking'
  bool _isProcessing = false;

  void _processUpgrade() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Trigger state upgrade with specific duration
    await ref.read(subscriptionProvider.notifier).upgradeToPro(
          planId: 'pro_$_selectedPlan',
          billingCycle: _selectedPlan,
        );

    final sub = ref.read(subscriptionProvider);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (!mounted) return;
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
            Text('👑 ', style: TextStyle(fontSize: 22)),
            Expanded(
              child: Text(
                'Welcome to CDA Pro!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your plan "${sub.planName}" is now active! Valid until:',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sub.expiryDate != null
                          ? '${sub.expiryDate!.day}/${sub.expiryDate!.month}/${sub.expiryDate!.year} ${sub.expiryDate!.hour.toString().padLeft(2, '0')}:${sub.expiryDate!.minute.toString().padLeft(2, '0')}'
                          : 'Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _ProFeatureBullet(text: 'Unlimited AI Mock Interviews'),
            const _ProFeatureBullet(text: 'Real-time Voice & Code Evaluation'),
            const _ProFeatureBullet(text: 'Fast-Track Job Applications'),
            const _ProFeatureBullet(text: 'Verified CDA Pro Profile Badge'),
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

  String _getButtonPriceLabel() {
    switch (_selectedPlan) {
      case '1_hour':
        return 'Pay ₹9 & Get 1-Hour Test Pass ⚡';
      case '1_day':
        return 'Pay ₹49 & Get 1-Day Sprint Pass ⚡';
      case '1_month':
        return 'Pay ₹499 & Get 1-Month Pro ⚡';
      case '3_months':
        return 'Pay ₹1,199 & Get 3-Month Quarter ⚡';
      case '1_year':
        return 'Pay ₹2,999 & Get 1-Year Annual 👑';
      default:
        return 'Pay Now & Become a Pro ⚡';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF090D16) : Colors.white;
    final bottomInset = MediaQuery.of(context).padding.bottom + 36;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'CDA PRO MEMBERSHIP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ALL ACCESS',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Unlock unlimited interviews, AI voice, & job fast-tracks',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Plan Picker (Horizontal / Grid Layout)
            Text(
              'SELECT DURATION PLAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Quick Testing Passes (1 Hour & 1 Day)
            Row(
              children: [
                Expanded(
                  child: _PlanCard(
                    title: '1-Hour Pass',
                    price: '₹9',
                    subtitle: 'Instant Test Pass',
                    badge: 'QUICK',
                    isSelected: _selectedPlan == '1_hour',
                    onTap: () => setState(() => _selectedPlan = '1_hour'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PlanCard(
                    title: '1-Day Pass',
                    price: '₹49',
                    subtitle: '24-Hour Sprint',
                    badge: 'DAILY',
                    isSelected: _selectedPlan == '1_day',
                    onTap: () => setState(() => _selectedPlan = '1_day'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Regular Subscriptions (1 Month, 3 Months, 1 Year)
            Row(
              children: [
                Expanded(
                  child: _PlanCard(
                    title: '1-Month Pro',
                    price: '₹499',
                    subtitle: '30 Days Access',
                    badge: 'POPULAR',
                    isSelected: _selectedPlan == '1_month',
                    onTap: () => setState(() => _selectedPlan = '1_month'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PlanCard(
                    title: '3-Month Quarter',
                    price: '₹1,199',
                    subtitle: '90 Days Access',
                    badge: 'SAVE 20%',
                    isSelected: _selectedPlan == '3_months',
                    onTap: () => setState(() => _selectedPlan = '3_months'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _PlanCard(
              title: '1-Year Annual Pass',
              price: '₹2,999',
              subtitle: '365 Days Unlimited Access • Best Value For Students',
              badge: '👑 BEST VALUE • SAVE 50%',
              isSelected: _selectedPlan == '1_year',
              onTap: () => setState(() => _selectedPlan = '1_year'),
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
                    label: _getButtonPriceLabel(),
                    variant: CDAButtonVariant.gold,
                    onTap: _processUpgrade,
                  ),
            const SizedBox(height: 12),

            Center(
              child: Text(
                '🔒 100% Instant Activation • Safe & Secure',
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF59E0B)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? Colors.black
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? const Color(0xFFF59E0B)
                    : (isDark ? Colors.white : AppColors.onSurface),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF59E0B)
                  : (isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFFF59E0B)
                      : (isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : (isDark ? Colors.white : AppColors.onSurface),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

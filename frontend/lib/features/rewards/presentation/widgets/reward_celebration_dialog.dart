import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/rewards_provider.dart';

void showRewardCelebrationDialog(
  BuildContext context, {
  required int coinsEarned,
  required String rewardTitle,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RewardCelebrationContent(
      coinsEarned: coinsEarned,
      rewardTitle: rewardTitle,
      isDark: isDark,
    ),
  );
}

class _RewardCelebrationContent extends ConsumerWidget {
  final int coinsEarned;
  final String rewardTitle;
  final bool isDark;

  const _RewardCelebrationContent({
    required this.coinsEarned,
    required this.rewardTitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 24),

            // CRED Glowing Coin Badge
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.credGoldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 54,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: const Text(
                'ACHIEVEMENT UNLOCKED',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Animated XP Counter
            TweenAnimationBuilder<int>(
              duration: const Duration(milliseconds: 1000),
              tween: IntTween(begin: 0, end: coinsEarned),
              builder: (context, val, _) => Text(
                '+$val XP POINTS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 6),
            Text(
              rewardTitle,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 28),

            // High-Tactile Claim Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ref.read(rewardsProvider.notifier).addCoins(coinsEarned, rewardTitle);
                  Navigator.pop(context);
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.credGoldGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Claim Rewards & Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

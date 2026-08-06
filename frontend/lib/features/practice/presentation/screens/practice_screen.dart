import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.marginMobile,
            vertical: AppConstants.stackMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Hero Section Card
              GlassCard(
                padding: const EdgeInsets.all(AppConstants.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'PREMIUM AI ACCESS',
                        style: AppTypography.codeMono.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Master your next career move.',
                      style: AppTypography.displayMobile.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Elevate your performance with state-of-the-art AI-driven mock interviews.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      text: 'Start AI Interview',
                      icon: Icons.bolt_rounded,
                      onPressed: () => context.push('/interview/setup'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.stackLg),

              // Interview Tracks Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Interview Tracks',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '3 TRACKS AVAILABLE',
                    style: AppTypography.codeMono.copyWith(
                      color: AppColors.outline,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildTrackCard(
                icon: Icons.code_rounded,
                title: 'Technical',
                description: 'System design, algorithms, and engineering challenges.',
                duration: '45-60 MINS',
                iconColor: AppColors.primary,
                onTap: () => context.push('/interview/setup'),
              ),
              const SizedBox(height: 10),
              _buildTrackCard(
                icon: Icons.groups_rounded,
                title: 'Cultural Fit',
                description: 'Values alignment, team dynamics, and soft-skill assessments.',
                duration: '20-30 MINS',
                iconColor: AppColors.secondary,
                onTap: () => context.push('/interview/setup'),
              ),
              const SizedBox(height: 10),
              _buildTrackCard(
                icon: Icons.psychology_rounded,
                title: 'Behavioral',
                description: 'STAR method coaching and leadership scenario simulations.',
                duration: '30-45 MINS',
                iconColor: AppColors.tertiary,
                onTap: () => context.push('/interview/setup'),
              ),

              const SizedBox(height: AppConstants.stackLg),

              // Resume & Analytics Bento Grid Section
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      onTap: () => context.push('/interview/session'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_rounded, color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'ONGOING',
                                style: AppTypography.codeMono.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Product Manager Role',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"Tell me about a time you had to pivot a strategy..."',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(
                            value: 0.35,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            color: AppColors.primary,
                            minHeight: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      onTap: () => context.push('/interview/analysis/rep-101'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Readiness Score',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '+5%',
                                style: AppTypography.codeMono.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '84%',
                            style: AppTypography.displayMobile.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [0.6, 0.45, 0.75, 0.65, 0.84].map((val) {
                              final isNow = val == 0.84;
                              return Container(
                                width: 8,
                                height: 30 * val,
                                decoration: BoxDecoration(
                                  color: isNow ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackCard({
    required IconData icon,
    required String title,
    required String description,
    required String duration,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      duration,
                      style: AppTypography.codeMono.copyWith(
                        color: AppColors.outline,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
        ],
      ),
    );
  }
}

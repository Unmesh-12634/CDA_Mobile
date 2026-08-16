import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../features/interview/data/models/interview_block_model.dart';

/// Dynamic "Box Type" widget for JD Interview Blocks
/// Automatically renders each block returned from the database.
class InterviewBlockCard extends StatelessWidget {
  final InterviewBlockModel block;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onStartPressed;
  final VoidCallback? onDeletePressed;

  const InterviewBlockCard({
    super.key,
    required this.block,
    required this.isSelected,
    required this.onTap,
    this.onStartPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : AppColors.outline.withValues(alpha: 0.15);
    final backgroundColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.surfaceContainerLow.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Icon, Title & Badge Tag
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        block.iconData,
                        color: isSelected ? AppColors.primary : AppColors.onSurface,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  block.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getBadgeColor(block.badgeTag).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: _getBadgeColor(block.badgeTag).withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  block.badgeTag.toUpperCase(),
                                  style: AppTypography.codeMono.copyWith(
                                    color: _getBadgeColor(block.badgeTag),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            block.companyName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.outline,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Selection Radio / Checkbox Indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description Text
                Text(
                  block.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Required Skills Chips Row
                if (block.requiredSkills.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: block.requiredSkills.take(4).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          skill,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Footer Row: Metadata Badges & Action CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          block.difficulty,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.outline,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.quiz_rounded, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${block.targetQuestionCount} Qs',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.outline,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.work_outline_rounded, size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          block.experienceLevel,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.outline,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    if (onStartPressed != null && isSelected)
                      GestureDetector(
                        onTap: onStartPressed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Select JD',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge.toUpperCase()) {
      case 'RECOMMENDED':
        return AppColors.primary;
      case 'HOT JD':
      case 'URGENT HIRING':
        return Colors.orangeAccent;
      case 'FAANG PASS':
      case 'PREMIUM':
        return Colors.purpleAccent;
      default:
        return AppColors.secondary;
    }
  }
}

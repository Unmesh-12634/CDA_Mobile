import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/quiz_provider.dart';
import '../../../rewards/presentation/widgets/reward_celebration_dialog.dart';

class DailyQuizScreen extends ConsumerWidget {
  const DailyQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: isDark ? AppColors.credDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    ref.read(quizProvider.notifier).restartQuiz();
                    context.go('/home');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: isDark ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              'Daily Skill Quiz',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'TEST YOUR KNOWLEDGE',
              style: AppTypography.codeMono.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Material(
                  color: isDark ? AppColors.credDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => ref.read(quizProvider.notifier).restartQuiz(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: quizState.isCompleted
                ? _buildResultsView(context, ref, quizState, isDark)
                : _buildQuestionView(context, ref, quizState, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionView(BuildContext context, WidgetRef ref, QuizState state, bool isDark) {
    final q = state.currentQuestion;
    final hasAnswered = state.selectedAnswers.containsKey(state.currentIndex);
    final selectedOption = state.selectedAnswers[state.currentIndex];
    final progress = (state.currentIndex + 1) / state.questions.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Meta: Category Pill Badge & Question Count ───────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Modern Capsule Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.08),
                      const Color(0xFF6063EE).withValues(alpha: isDark ? 0.12 : 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.18),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.psychology_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      q.category.toUpperCase(),
                      style: AppTypography.codeMono.copyWith(
                        color: isDark ? const Color(0xFFA5B4FC) : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Question Step Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.credDarkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  '${state.currentIndex + 1} of ${state.questions.length}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress Bar ──────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROGRESS',
                    style: AppTypography.codeMono.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  builder: (context, val, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: val,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Question Card Container ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.credDarkCard, AppColors.credDarkBase]
                    : [Colors.white, const Color(0xFFFBFDFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFECEEF0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'QUESTION',
                      style: AppTypography.codeMono.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  q.question,
                  style: AppTypography.displayMobile.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Interactive Answer Options Cards ────────────────────────────────
          ...List.generate(q.options.length, (index) {
            final optionText = q.options[index];
            final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
            final isSelected = selectedOption == index;
            final isCorrect = index == q.correctOptionIndex;

            Color bgColor = isDark ? AppColors.credDarkCard : Colors.white;
            Color borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);
            Color textColor = isDark ? const Color(0xFFF1F5F9) : AppColors.onSurface;
            Color letterBgColor = isDark ? const Color(0xFF1E2D4A) : const Color(0xFFF1F5F9);
            Color letterTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;
            IconData? trailingIcon;
            Color iconColor = AppColors.primary;

            if (isSelected && !hasAnswered) {
              bgColor = AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.06);
              borderColor = AppColors.primary;
              textColor = isDark ? Colors.white : AppColors.primary;
              letterBgColor = AppColors.primary;
              letterTextColor = Colors.white;
            }

            if (hasAnswered) {
              if (isCorrect) {
                bgColor = const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08);
                borderColor = const Color(0xFF10B981);
                textColor = isDark ? Colors.white : const Color(0xFF047857);
                letterBgColor = const Color(0xFF10B981);
                letterTextColor = Colors.white;
                trailingIcon = Icons.check_circle_rounded;
                iconColor = const Color(0xFF10B981);
              } else if (isSelected && !isCorrect) {
                bgColor = AppColors.error.withValues(alpha: isDark ? 0.15 : 0.06);
                borderColor = AppColors.error;
                textColor = isDark ? Colors.white : AppColors.error;
                letterBgColor = AppColors.error;
                letterTextColor = Colors.white;
                trailingIcon = Icons.cancel_rounded;
                iconColor = AppColors.error;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionCard(
                text: optionText,
                letter: optionLetter,
                isSelected: isSelected,
                hasAnswered: hasAnswered,
                isCorrect: isCorrect,
                bgColor: bgColor,
                borderColor: borderColor,
                textColor: textColor,
                letterBgColor: letterBgColor,
                letterTextColor: letterTextColor,
                trailingIcon: trailingIcon,
                iconColor: iconColor,
                onTap: () {
                  ref.read(quizProvider.notifier).selectAnswer(index);
                },
                isDark: isDark,
              ),
            );
          }),

          // ── Explanation Card (When Question is Answered) ────────────────────
          if (hasAnswered) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.3 : 0.15),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF6366F1), size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EXPLANATION',
                        style: AppTypography.codeMono.copyWith(
                          color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    q.explanation,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurface,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: state.currentIndex == state.questions.length - 1 ? 'View Final Results' : 'Next Question',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                final isLast = state.currentIndex == state.questions.length - 1;
                ref.read(quizProvider.notifier).nextQuestion();
                if (isLast && state.score >= 60) {
                  showRewardCelebrationDialog(
                    context,
                    coinsEarned: 150,
                    rewardTitle: 'Daily Skill Challenge Mastered!',
                  );
                }
              },
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Results Summary View ──────────────────────────────────────────────────
  Widget _buildResultsView(BuildContext context, WidgetRef ref, QuizState state, bool isDark) {
    final passed = state.score >= 60;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Score Badge Card Container
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.credDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: passed
                        ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12)
                        : AppColors.error.withValues(alpha: isDark ? 0.2 : 0.12),
                    border: Border.all(
                      color: passed ? const Color(0xFF10B981) : AppColors.error,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    passed ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                    color: passed ? const Color(0xFF10B981) : AppColors.error,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${state.score} / 100',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  passed ? 'Quiz Completed Successfully!' : 'Keep Practicing to Unlock Badges',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: passed ? const Color(0xFF10B981) : AppColors.error,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 6),
                      Text(
                        '+1 Day Streak Boosted!',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Questions Summary Breakdown Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'QUESTION SUMMARY',
              style: AppTypography.codeMono.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(state.questions.length, (i) {
            final q = state.questions[i];
            final userAns = state.selectedAnswers[i];
            final isCorrect = userAns == q.correctOptionIndex;

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? const Color(0xFF10B981) : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.question,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isCorrect ? 'Correct' : 'Correct Answer: ${q.options[q.correctOptionIndex]}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isCorrect ? const Color(0xFF10B981) : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Action buttons
          GradientButton(
            text: 'Try Another Quiz Session',
            icon: Icons.replay_rounded,
            onPressed: () {
              ref.read(quizProvider.notifier).restartQuiz();
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                ref.read(quizProvider.notifier).restartQuiz();
                context.go('/home');
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: isDark ? AppColors.credDarkBorder : const Color(0xFFCBD5E1)),
              ),
              child: Text(
                'Return to Home',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Custom Interactive Option Card Widget with Springy Press Animation ───────
class _OptionCard extends StatefulWidget {
  final String text;
  final String letter;
  final bool isSelected;
  final bool hasAnswered;
  final bool isCorrect;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color letterBgColor;
  final Color letterTextColor;
  final IconData? trailingIcon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDark;

  const _OptionCard({
    required this.text,
    required this.letter,
    required this.isSelected,
    required this.hasAnswered,
    required this.isCorrect,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.letterBgColor,
    required this.letterTextColor,
    required this.trailingIcon,
    required this.iconColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (!widget.hasAnswered) {
      setState(() {
        _scale = 0.975;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.hasAnswered) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _onTapCancel() {
    if (!widget.hasAnswered) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.borderColor,
              width: (widget.isSelected || (widget.hasAnswered && widget.isCorrect)) ? 2.0 : 1.2,
            ),
            boxShadow: [
              if (widget.isSelected || (widget.hasAnswered && widget.isCorrect))
                BoxShadow(
                  color: widget.borderColor.withValues(alpha: widget.isDark ? 0.25 : 0.18),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.02),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Option Letter badge (A, B, C, D)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.letterBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (widget.isSelected || (widget.hasAnswered && widget.isCorrect))
                        ? Colors.transparent
                        : (widget.isDark ? const Color(0xFF2A3C5D) : const Color(0xFFCBD5E1)),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.letter,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: widget.letterTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Option Text
              Expanded(
                child: Text(
                  widget.text,
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                    color: widget.textColor,
                    height: 1.35,
                  ),
                ),
              ),

              // Trailing Status Indicator Icon
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(widget.trailingIcon, color: widget.iconColor, size: 22),
                ),
              ] else if (widget.isSelected && !widget.hasAnswered) ...[
                const SizedBox(width: 10),
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

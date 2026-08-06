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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.onSurface),
          onPressed: () {
            ref.read(quizProvider.notifier).restartQuiz();
            context.go('/home');
          },
        ),
        title: Text(
          'Daily Skill Quiz',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : AppColors.primary),
            onPressed: () => ref.read(quizProvider.notifier).restartQuiz(),
          ),
        ],
      ),
      body: SafeArea(
        child: quizState.isCompleted
            ? _buildResultsView(context, ref, quizState, isDark)
            : _buildQuestionView(context, ref, quizState, isDark),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Progress & Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      q.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Question ${state.currentIndex + 1} of ${state.questions.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 24),

          // Question Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                Text(
                  q.question,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options List
          ...List.generate(q.options.length, (index) {
            final optionText = q.options[index];
            final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
            final isSelected = selectedOption == index;
            final isCorrect = index == q.correctOptionIndex;

            Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
            Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
            Color textColor = isDark ? Colors.white : AppColors.onSurface;
            Color letterBgColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
            Color letterTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;
            IconData? trailingIcon;

            if (hasAnswered) {
              if (isCorrect) {
                bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                borderColor = const Color(0xFF10B981);
                textColor = const Color(0xFF10B981);
                letterBgColor = const Color(0xFF10B981);
                letterTextColor = Colors.white;
                trailingIcon = Icons.check_circle_rounded;
              } else if (isSelected && !isCorrect) {
                bgColor = AppColors.error.withValues(alpha: 0.12);
                borderColor = AppColors.error;
                textColor = AppColors.error;
                letterBgColor = AppColors.error;
                letterTextColor = Colors.white;
                trailingIcon = Icons.cancel_rounded;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  ref.read(quizProvider.notifier).selectAnswer(index);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: isSelected || (hasAnswered && isCorrect) ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: letterBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            optionLetter,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: letterTextColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        Icon(trailingIcon, color: isCorrect ? const Color(0xFF10B981) : AppColors.error, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explanation Banner when answered
          if (hasAnswered) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Color(0xFF6366F1), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'EXPLANATION',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurface,
                      height: 1.4,
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

  // Results View at Quiz End
  Widget _buildResultsView(BuildContext context, WidgetRef ref, QuizState state, bool isDark) {
    final passed = state.score >= 60;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Score Badge Container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: passed ? const Color(0xFF10B981).withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    passed ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                    color: passed ? const Color(0xFF10B981) : AppColors.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${state.score} / 100',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  passed ? 'Quiz Completed Successfully!' : 'Keep Practicing to Unlock Badges',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: passed ? const Color(0xFF10B981) : AppColors.error,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 16),
                      SizedBox(width: 5),
                      Text(
                        '+1 Day Streak Boosted!',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Questions Summary Breakdown
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'QUESTION SUMMARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          ...List.generate(state.questions.length, (i) {
            final q = state.questions[i];
            final userAns = state.selectedAnswers[i];
            final isCorrect = userAns == q.correctOptionIndex;

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? const Color(0xFF10B981) : AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.question,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCorrect ? 'Correct' : 'Correct Answer: ${q.options[q.correctOptionIndex]}',
                          style: TextStyle(
                            fontSize: 11,
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
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                ref.read(quizProvider.notifier).restartQuiz();
                context.go('/home');
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: Text(
                'Return to Home',
                style: TextStyle(color: isDark ? Colors.white70 : AppColors.onSurface, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

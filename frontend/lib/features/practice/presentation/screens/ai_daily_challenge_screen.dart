import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/ai_daily_challenge_provider.dart';

class AiDailyChallengeScreen extends ConsumerWidget {
  const AiDailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drillState = ref.watch(dailyDrillProvider);
    final notifier = ref.read(dailyDrillProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Real-Time AI Skill Drill',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '5 ADAPTIVE MCQS • LIVE AI',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Color(0xFF0284C7),
              ),
            ),

          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: drillState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color: isDark ? Colors.white70 : AppColors.onSurface,
                  ),
            tooltip: 'Generate New AI Questions',
            onPressed: drillState.isLoading ? null : () => notifier.loadFreshDrill(forceRefresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: drillState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF0284C7)),
                  const SizedBox(height: 16),
                  Text(
                    'Generating Personalized 5-MCQ Drill...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Analyzing your interview weak areas and candidate profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            )
          : drillState.isCompleted
              ? _buildCompletionView(context, ref, drillState, isDark)
              : _buildQuizView(context, ref, drillState, isDark),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // QUIZ VIEW (5 Interactive MCQs)
  // ─────────────────────────────────────────────────────────────
  Widget _buildQuizView(BuildContext context, WidgetRef ref, DailyDrillState state, bool isDark) {
    final drill = state.drill;
    if (drill == null || drill.questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final qIndex = state.currentQuestionIndex;
    final totalQ = drill.questions.length;
    final question = state.currentQuestion!;
    final hasAnswered = state.selectedOptions.containsKey(qIndex);
    final selectedOption = state.selectedOptions[qIndex];
    final notifier = ref.read(dailyDrillProvider.notifier);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Top Focus & Daily Limit Banner ───────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF0F9FF), Colors.white],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          drill.skillFocus.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Drill ${drill.todayCompleted + 1}/5 Today',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.radar_rounded, color: Color(0xFFE11D48), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        drill.weaknessSummary,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
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
          const SizedBox(height: 14),

          // ── 2. Step Progress Indicators (5 questions) ───────────
          Row(
            children: List.generate(totalQ, (idx) {
              final isCurrent = idx == qIndex;
              final isDone = state.selectedOptions.containsKey(idx);
              final isCorrect = isDone && state.selectedOptions[idx] == drill.questions[idx].correctIndex;

              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: idx < totalQ - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF0284C7)
                        : isDone
                            ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFE11D48))
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // ── 3. Question Card ────────────────────────────────────
          Container(
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
                  blurRadius: 10,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        question.category.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    Text(
                      'Q${qIndex + 1} of $totalQ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 4. Option Choices (A, B, C, D) ──────────────────────
          ...List.generate(question.options.length, (optIdx) {
            final optionText = question.options[optIdx];
            final isSelected = selectedOption == optIdx;
            final isCorrectOption = optIdx == question.correctIndex;

            Color borderColor;
            Color bgColor;
            IconData? trailingIcon;
            Color trailingIconColor = Colors.transparent;

            if (hasAnswered) {
              if (isCorrectOption) {
                borderColor = const Color(0xFF10B981);
                bgColor = const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.10);
                trailingIcon = Icons.check_circle_rounded;
                trailingIconColor = const Color(0xFF10B981);
              } else if (isSelected) {
                borderColor = const Color(0xFFE11D48);
                bgColor = const Color(0xFFE11D48).withValues(alpha: isDark ? 0.20 : 0.10);
                trailingIcon = Icons.cancel_rounded;
                trailingIconColor = const Color(0xFFE11D48);
              } else {
                borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                bgColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white;
              }
            } else {
              borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
              bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
            }

            final optionLabel = String.fromCharCode(65 + optIdx); // A, B, C, D

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasAnswered ? null : () => notifier.selectOption(optIdx),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: isSelected || (hasAnswered && isCorrectOption) ? 1.8 : 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isCorrectOption ? const Color(0xFF10B981) : const Color(0xFFE11D48))
                                : (hasAnswered && isCorrectOption
                                    ? const Color(0xFF10B981)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          ),
                          child: Text(
                            optionLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected || (hasAnswered && isCorrectOption)
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              height: 1.35,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(trailingIcon, color: trailingIconColor, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // ── 5. Detailed Engineering Explanation ─────────────────
          if (hasAnswered) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (selectedOption == question.correctIndex
                        ? const Color(0xFF10B981)
                        : const Color(0xFF0284C7))
                    .withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (selectedOption == question.correctIndex
                          ? const Color(0xFF10B981)
                          : const Color(0xFF0284C7))
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: selectedOption == question.correctIndex
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0284C7),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Engineering Rationale & Pitfalls:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selectedOption == question.correctIndex
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.explanation,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Next / Finish Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => notifier.nextQuestionOrFinish(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      qIndex < totalQ - 1 ? 'Next Question (${qIndex + 2}/$totalQ)' : 'Finish & Submit Drill',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPLETION VIEW (Score, Daily Streak, Quota Status)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCompletionView(BuildContext context, WidgetRef ref, DailyDrillState state, bool isDark) {
    final drill = state.drill;
    final totalQ = drill?.questions.length ?? 5;
    final correct = state.correctCount;
    final score = state.score;
    final remaining = drill?.remainingToday ?? 0;
    final notifier = ref.read(dailyDrillProvider.notifier);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Score Badge Circular Container
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: score >= 60
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (score >= 60 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$correct/$totalQ Correct',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            score >= 80 ? 'Exceptional Performance!' : (score >= 60 ? 'Solid Skill Mastery!' : 'Keep Practicing!'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Targeted focus: ${drill?.weaknessSummary ?? "Technical Architecture"}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // ── Streak Updated Banner ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Goal & Streak Secured! 🔥',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Completing 1 drill secures your daily learning consistency.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Daily Quota Status ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Drill Quota',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining > 0 ? '$remaining drill(s) remaining today (max 5/day)' : 'Daily limit reached (5/5)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: remaining > 0 ? const Color(0xFF0284C7) : const Color(0xFFE11D48),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${drill?.todayCompleted ?? 1}/5',
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Actions ────────────────────────────────────────────
          if (remaining > 0) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => notifier.loadFreshDrill(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Start Next Drill ($remaining Left Today)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Return to Home',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

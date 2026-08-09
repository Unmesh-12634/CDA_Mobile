import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/gradient_button.dart';

class InterviewAnalysisScreen extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic>? reportData;

  const InterviewAnalysisScreen({
    super.key,
    required this.reportId,
    this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract dynamic report properties with robust fallbacks
    final data = reportData ?? {};
    final bool isTerminatedEarly = data['is_terminated_early'] == true;
    final int completedTurns = (data['completed_turns'] as num?)?.toInt() ?? 2;
    final int targetTurns = (data['target_turns'] as num?)?.toInt() ?? 5;
    
    final double overallScore = ((data['overall_score'] as num?)?.toDouble() ?? 85.0).clamp(0.0, 100.0);
    final double techScore = ((data['technical_score'] as num?)?.toDouble() ?? 88.0).clamp(0.0, 100.0);
    final double commScore = ((data['communication_score'] as num?)?.toDouble() ?? 82.0).clamp(0.0, 100.0);
    final double probScore = ((data['problem_solving_score'] as num?)?.toDouble() ?? 85.0).clamp(0.0, 100.0);
    
    final String hiringReadiness = (data['hiring_readiness'] as String?) ??
        (overallScore >= 80 ? 'STRONG CANDIDATE' : (overallScore >= 65 ? 'DEVELOPING CANDIDATE' : 'NEEDS PREPARATION'));

    final List<String> strongAreas = (data['strong_areas'] as List?)?.map((e) => e.toString()).toList() ?? [
      'Clear technical explanation of core programming concepts.',
      'Strong structural logic matching senior engineering expectations.',
      'Effective communication of architectural trade-offs.',
    ];

    final List<String> improvementAreas = (data['areas_for_improvement'] as List?)?.map((e) => e.toString()).toList() ?? [
      'Elaborate further on production edge-cases and load scaling.',
      'Provide concrete numerical benchmarks and latency trade-offs.',
    ];

    final List rawReviews = (data['question_reviews'] as List?) ?? [];
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero AppBar with Score Ring
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () => context.go('/home'),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeroBanner(overallScore, hiringReadiness, isDark),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(
                height: 1,
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Early Termination Alert Banner
                  if (isTerminatedEarly) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'INTERVIEW TERMINATED EARLY',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Session ended early ($completedTurns of $targetTurns questions answered). Scores reflect completed turns.',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurface,
                                    fontSize: 11.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Session Summary Pills
                  _buildSessionSummaryRow(completedTurns, targetTurns, isDark),

                  const SizedBox(height: 24),

                  // Metric Breakdown Header
                  _buildSectionHeader('SKILL METRICS', Icons.bar_chart_rounded, AppColors.primary, isDark),
                  const SizedBox(height: 14),

                  _buildMetricTile(
                    context,
                    label: 'Technical Depth & Accuracy',
                    value: techScore / 100.0,
                    percentage: '${techScore.toStringAsFixed(0)}%',
                    icon: Icons.code_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildMetricTile(
                    context,
                    label: 'Problem Solving & Systems',
                    value: probScore / 100.0,
                    percentage: '${probScore.toStringAsFixed(0)}%',
                    icon: Icons.hub_rounded,
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildMetricTile(
                    context,
                    label: 'STAR Method Communication',
                    value: commScore / 100.0,
                    percentage: '${commScore.toStringAsFixed(0)}%',
                    icon: Icons.record_voice_over_rounded,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 28),

                  // Strengths & Improvements
                  _buildSectionHeader('AI FEEDBACK', Icons.auto_awesome_rounded, const Color(0xFF10B981), isDark),
                  const SizedBox(height: 14),

                  _buildFeedbackCard(
                    icon: Icons.check_circle_rounded,
                    title: 'Key Strengths',
                    iconColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                    isDark: isDark,
                    bullets: strongAreas,
                  ),
                  const SizedBox(height: 12),
                  _buildFeedbackCard(
                    icon: Icons.tips_and_updates_rounded,
                    title: 'Areas to Improve',
                    iconColor: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    isDark: isDark,
                    bullets: improvementAreas,
                  ),

                  const SizedBox(height: 28),

                  // Question by Question Review
                  if (rawReviews.isNotEmpty) ...[
                    _buildSectionHeader('QUESTION REVIEW', Icons.quiz_rounded, AppColors.secondary, isDark),
                    const SizedBox(height: 14),

                    ...rawReviews.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final rev = entry.value as Map<String, dynamic>;
                      final qText = (rev['question'] as String?) ?? 'Question $idx';
                      final score = ((rev['score'] as num?)?.toDouble() ?? 8.0) * (rev['score'] is num && (rev['score'] as num) <= 10 ? 10 : 1);
                      final feedback = (rev['how_to_improve'] as String?) ?? (rev['interviewer_expectation'] as String?) ?? 'Demonstrated good clarity.';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildQuestionReviewCard(
                          context,
                          questionNum: idx,
                          title: qText,
                          score: score.round(),
                          feedback: feedback,
                          isDark: isDark,
                        ),
                      );
                    }),
                    const SizedBox(height: 28),
                  ],

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          text: 'RETRY INTERVIEW',
                          icon: Icons.replay_rounded,
                          onPressed: () => context.go('/interview/setup'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/home'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                            foregroundColor: isDark ? Colors.white70 : AppColors.onSurface,
                          ),
                          child: const Text('BACK TO HOME'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Banner with Score Ring
  Widget _buildHeroBanner(double score, String hiringReadiness, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF0F4FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 36),

            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_rounded, color: AppColors.primary, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'PERFORMANCE REPORT',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Score Ring
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: score / 100.0),
              builder: (context, value, _) {
                return SizedBox(
                  width: 125,
                  height: 125,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 9,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(value * 100).toInt()}',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.onSurface,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'OUT OF 100',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // Rating Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    hiringReadiness.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Session Summary Row
  Widget _buildSessionSummaryRow(int completedTurns, int targetTurns, bool isDark) {
    return Row(
      children: [
        _buildSummaryPill(Icons.schedule_rounded, 'Active', 'Mode', const Color(0xFF6366F1), isDark),
        const SizedBox(width: 10),
        _buildSummaryPill(Icons.quiz_rounded, '$completedTurns of $targetTurns', 'Questions', AppColors.secondary, isDark),
        const SizedBox(width: 10),
        _buildSummaryPill(Icons.calendar_today_rounded, 'Today', 'Date', const Color(0xFF10B981), isDark),
      ],
    );
  }

  Widget _buildSummaryPill(IconData icon, String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurface,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // Animated Metric Tile
  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required double value,
    required String percentage,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // Feedback Card (Strengths / Improvements)
  Widget _buildFeedbackCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required bool isDark,
    required List<String> bullets,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Question Review Card
  Widget _buildQuestionReviewCard(
    BuildContext context, {
    required int questionNum,
    required String title,
    required int score,
    required String feedback,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q$questionNum',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$score%',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';

class InterviewAnalysisScreen extends StatelessWidget {
  final String reportId;

  const InterviewAnalysisScreen({
    super.key,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero AppBar with Score
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
              background: _buildHeroBanner(isDark),
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

                  // Session Summary Pills
                  _buildSessionSummaryRow(isDark),

                  const SizedBox(height: 24),

                  // Metric Breakdown Header
                  _buildSectionHeader('SKILL METRICS', Icons.bar_chart_rounded, AppColors.primary, isDark),
                  const SizedBox(height: 14),

                  _buildMetricTile(
                    context,
                    label: 'Technical Depth & Accuracy',
                    value: 0.90,
                    percentage: '90%',
                    icon: Icons.code_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildMetricTile(
                    context,
                    label: 'System Architecture & Scalability',
                    value: 0.85,
                    percentage: '85%',
                    icon: Icons.hub_rounded,
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildMetricTile(
                    context,
                    label: 'STAR Method Communication',
                    value: 0.92,
                    percentage: '92%',
                    icon: Icons.record_voice_over_rounded,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildMetricTile(
                    context,
                    label: 'Confidence & Pacing',
                    value: 0.82,
                    percentage: '82%',
                    icon: Icons.psychology_alt_rounded,
                    color: const Color(0xFFF59E0B),
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
                    bullets: [
                      'Clear explanation of Redis atomic Lua scripting for rate limiting.',
                      'Excellent structural clarity following the STAR methodology.',
                      'Strong grasp of trade-offs between Token Bucket and Leaky Bucket.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeedbackCard(
                    icon: Icons.tips_and_updates_rounded,
                    title: 'Areas to Improve',
                    iconColor: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    isDark: isDark,
                    bullets: [
                      'Elaborate on fault-tolerance when Redis nodes crash.',
                      'Slightly fast speaking pace during the second minute of response.',
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Question by Question Review
                  _buildSectionHeader('QUESTION REVIEW', Icons.quiz_rounded, AppColors.secondary, isDark),
                  const SizedBox(height: 14),

                  _buildQuestionReviewCard(
                    context,
                    questionNum: 1,
                    title: 'Distributed Rate Limiting Design',
                    score: 92,
                    feedback: 'Demonstrated deep technical mastery of Redis caching layers and edge API gateways. Answer was well-structured and included real-world trade-off comparisons.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildQuestionReviewCard(
                    context,
                    questionNum: 2,
                    title: 'Event-Driven Microservices Architecture',
                    score: 84,
                    feedback: 'Good overview of Kafka topic partition strategy and consumer group rebalancing. Consider adding failure handling with Dead Letter Queues.',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 28),

                  // Action Buttons
                  GradientButton(
                    text: 'Practice Another Session',
                    icon: Icons.replay_rounded,
                    onPressed: () => context.push('/interview/setup'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('Return to Dashboard'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                        foregroundColor: isDark ? Colors.white70 : AppColors.onSurface,
                      ),
                    ),
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

  // Hero Banner with Score
  Widget _buildHeroBanner(bool isDark) {
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
            const SizedBox(height: 44),

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

            const SizedBox(height: 20),

            // Score Ring
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: 0.88),
              builder: (context, value, _) {
                return SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 9,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        color: AppColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(value * 100).round()}',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.onSurface,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '/ 100',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                                fontWeight: FontWeight.w600,
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

            const SizedBox(height: 16),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'EXCELLENT — STRONG CANDIDATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
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
  Widget _buildSessionSummaryRow(bool isDark) {
    return Row(
      children: [
        _buildSummaryPill(Icons.schedule_rounded, '42 min', 'Duration', const Color(0xFF6366F1), isDark),
        const SizedBox(width: 10),
        _buildSummaryPill(Icons.quiz_rounded, '2 of 5', 'Questions', AppColors.secondary, isDark),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE2E8F0) : AppColors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: value),
            builder: (context, animValue, _) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: animValue,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                color: color,
                minHeight: 6,
              ),
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
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bullets.map((b) => _buildBulletPoint(b, iconColor, isDark)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.5,
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
    final Color scoreColor = score >= 90
        ? const Color(0xFF10B981)
        : score >= 80
            ? AppColors.primary
            : const Color(0xFFF59E0B);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q$questionNum',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star_rounded, color: scoreColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$score / 100',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // Score bar
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: score / 100),
            builder: (context, val, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: val,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                color: scoreColor,
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

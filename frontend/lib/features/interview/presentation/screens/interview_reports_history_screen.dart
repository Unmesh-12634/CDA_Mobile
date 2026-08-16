import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/ai_interview_service.dart';

class InterviewReportsHistoryScreen extends ConsumerStatefulWidget {
  const InterviewReportsHistoryScreen({super.key});

  @override
  ConsumerState<InterviewReportsHistoryScreen> createState() => _InterviewReportsHistoryScreenState();
}

class _InterviewReportsHistoryScreenState extends ConsumerState<InterviewReportsHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final api = ref.read(aiInterviewServiceProvider);
    final fetched = await api.fetchInterviewHistory();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _reports = fetched.map((item) {
          final qaJson = item['detailed_qa_json'] as Map<String, dynamic>? ?? item;
          final score = (item['overall_score'] as num?)?.toDouble() ?? (qaJson['overall_score'] as num?)?.toDouble() ?? 85.0;
          final role = item['target_role'] ?? 'Software Developer';
          final dateStr = item['created_at'] != null
              ? item['created_at'].toString().split('T').first
              : 'Recent Session';
          final dynamicSkills = (item['strengths'] as List?)?.map((e) => e.toString()).toList() ??
              (qaJson['skills'] as List?)?.map((e) => e.toString()).toList() ??
              ['Technical', 'System Design'];

          return {
            'id': item['id']?.toString() ?? 'rep-${DateTime.now().millisecondsSinceEpoch}',
            'role': role,
            'date': dateStr,
            'type': qaJson['interview_type'] ?? 'Technical Session',
            'score': score,
            'hiringReadiness': score >= 80 ? 'STRONG CANDIDATE' : 'DEVELOPING CANDIDATE',
            'skills': dynamicSkills,
            'data': qaJson,
          };
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Interview Reports History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Analytics Header Summary ──────────────────────────
          GlassCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_reports.length} Sessions Evaluated',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Avg. Technical Score: ${(_reports.isNotEmpty ? (_reports.fold<double>(0, (sum, r) => sum + (r['score'] as double)) / _reports.length) : 85.0).toStringAsFixed(1)}% · Strong Candidate',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'PAST INTERVIEW SESSIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined,
                        size: 48,
                        color: isDark ? const Color(0xFF64748B) : AppColors.outline),
                    const SizedBox(height: 12),
                    Text(
                      'No AI interview reports yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start an AI interview to get real-time feedback and score breakdown.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── Report Cards ──────────────────────────────────────
            ..._reports.map((report) {
            final double score = report['score'] as double;
            final Color scoreColor = score >= 85
                ? const Color(0xFF10B981)
                : (score >= 75 ? AppColors.primary : Colors.orange);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: isDark ? const Color(0xFF1E273A) : Colors.white,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                child: InkWell(
                  onTap: () => context.push('/interview/analysis/${report['id']}', extra: report['data']),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report['role'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${report['type']} · ${report['date']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded, color: scoreColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${score.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: scoreColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (report['skills'] as List<String>).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            report['hiringReadiness'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                'View Full Analysis',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 12),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

class InterviewReportsHistoryScreen extends StatelessWidget {
  const InterviewReportsHistoryScreen({super.key});

  static final List<Map<String, dynamic>> _mockReports = [
    {
      'id': 'rep-101',
      'role': 'Senior Flutter Architect',
      'date': 'Feb 10, 2026 · 14:30',
      'type': 'Technical & Architecture',
      'score': 92.0,
      'techScore': 94.0,
      'commScore': 90.0,
      'probScore': 92.0,
      'hiringReadiness': 'STRONG CANDIDATE',
      'turns': 5,
      'skills': ['Flutter 3.27', 'Riverpod', 'Clean Architecture', 'Dart'],
      'data': {
        'overall_score': 92.0,
        'technical_score': 94.0,
        'communication_score': 90.0,
        'problem_solving_score': 92.0,
        'hiring_readiness': 'STRONG CANDIDATE',
        'completed_turns': 5,
        'target_turns': 5,
        'strong_areas': [
          'Mastery over Flutter widget tree optimization and state management.',
          'Demonstrated excellent grasp of Riverpod reactivity and dynamic dependency injection.',
          'Clear communication of architectural boundaries and clean code principles.',
        ],
        'areas_for_improvement': [
          'Elaborate further on native platform channels (iOS Swift & Android Kotlin integration).',
          'Provide concrete frame render metrics (120Hz Jank analysis).',
        ],
      },
    },
    {
      'id': 'rep-102',
      'role': 'Full-Stack Engineer (Python & React)',
      'date': 'Feb 8, 2026 · 18:15',
      'type': 'System Design & REST API',
      'score': 88.0,
      'techScore': 90.0,
      'commScore': 86.0,
      'probScore': 88.0,
      'hiringReadiness': 'STRONG CANDIDATE',
      'turns': 5,
      'skills': ['FastAPI', 'Groq LLM', 'React 19', 'PostgreSQL'],
      'data': {
        'overall_score': 88.0,
        'technical_score': 90.0,
        'communication_score': 86.0,
        'problem_solving_score': 88.0,
        'hiring_readiness': 'STRONG CANDIDATE',
        'completed_turns': 5,
        'target_turns': 5,
        'strong_areas': [
          'Solid understanding of async Python FastAPI request lifecycle.',
          'Effective application of LLM prompt engineering and Groq API cascades.',
        ],
        'areas_for_improvement': [
          'Include Redis caching strategies for database query optimization under high concurrency.',
        ],
      },
    },
    {
      'id': 'rep-103',
      'role': 'JVM / Java Backend Developer',
      'date': 'Feb 5, 2026 · 11:00',
      'type': 'Algorithms & Concurrency',
      'score': 84.0,
      'techScore': 85.0,
      'commScore': 82.0,
      'probScore': 85.0,
      'hiringReadiness': 'DEVELOPING CANDIDATE',
      'turns': 5,
      'skills': ['Java 21', 'Spring Boot 3', 'Virtual Threads', 'Microservices'],
      'data': {
        'overall_score': 84.0,
        'technical_score': 85.0,
        'communication_score': 82.0,
        'problem_solving_score': 85.0,
        'hiring_readiness': 'DEVELOPING CANDIDATE',
        'completed_turns': 5,
        'target_turns': 5,
        'strong_areas': [
          'Good grasp of Java 21 Virtual Threads and ExecutorService concurrency.',
          'Solid understanding of Spring Security filter chains.',
        ],
        'areas_for_improvement': [
          'Deepen knowledge of JVM garbage collector tuning (ZGC vs G1GC).',
        ],
      },
    },
    {
      'id': 'rep-104',
      'role': 'AI / ML Systems Engineer',
      'date': 'Jan 28, 2026 · 16:45',
      'type': 'RAG & Vector Search',
      'score': 79.0,
      'techScore': 80.0,
      'commScore': 78.0,
      'probScore': 79.0,
      'hiringReadiness': 'DEVELOPING CANDIDATE',
      'turns': 4,
      'skills': ['Python', 'LangChain', 'Pinecone', 'RAG Pipelines'],
      'data': {
        'overall_score': 79.0,
        'technical_score': 80.0,
        'communication_score': 78.0,
        'problem_solving_score': 79.0,
        'hiring_readiness': 'DEVELOPING CANDIDATE',
        'completed_turns': 4,
        'target_turns': 5,
        'strong_areas': [
          'Clear explanation of embedding chunking strategies and cosine similarity.',
        ],
        'areas_for_improvement': [
          'Elaborate on hybrid search (BM25 + Dense vector retrieval).',
        ],
      },
    },
  ];

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
                        '4 Sessions Evaluated',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Avg. Technical Score: 87.5% · Strong Candidate',
                        style: TextStyle(
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

          // ── Report Cards ──────────────────────────────────────
          ..._mockReports.map((report) {
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
                          Row(
                            children: [
                              Text(
                                'View Full Analysis',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 12),
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

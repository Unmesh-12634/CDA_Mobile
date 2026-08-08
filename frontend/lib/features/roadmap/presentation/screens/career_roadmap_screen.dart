import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class CareerRoadmapScreen extends StatefulWidget {
  const CareerRoadmapScreen({super.key});

  @override
  State<CareerRoadmapScreen> createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen> {
  int _selectedPathIndex = 0;

  final List<Map<String, dynamic>> _paths = [
    {
      'title': 'Full-Stack Java Engineer',
      'icon': Icons.code_rounded,
      'salary': '₹8 - 18 LPA',
      'jobs': '24,500+ Openings',
      'color': const Color(0xFF6366F1),
      'phases': [
        {
          'phase': 'Phase 1',
          'title': 'Java Language Fundamentals & OOP',
          'status': 'Completed',
          'progress': 1.0,
          'topics': ['Core Java Syntax', 'Object-Oriented Programming', 'Collections Framework', 'Exception Handling'],
        },
        {
          'phase': 'Phase 2',
          'title': 'Data Structures & Algorithmic Problem Solving',
          'status': 'In Progress',
          'progress': 0.65,
          'topics': ['Arrays & Linked Lists', 'Trees & Graphs', 'Sorting & Searching', 'Dynamic Programming Basics'],
        },
        {
          'phase': 'Phase 3',
          'title': 'Spring Boot & Microservices Architecture',
          'status': 'Up Next',
          'progress': 0.0,
          'topics': ['Spring Core & MVC', 'RESTful API Design', 'Spring Data JPA & Hibernate', 'Microservices & Gateway'],
        },
        {
          'phase': 'Phase 4',
          'title': 'Database Optimization & Cloud Deployment',
          'status': 'Locked',
          'progress': 0.0,
          'topics': ['PostgreSQL & Indexing', 'Redis Caching', 'Docker & Kubernetes', 'AWS / Cloud Deployment'],
        },
        {
          'phase': 'Phase 5',
          'title': 'Placement Readiness & AI Interview Drills',
          'status': 'Locked',
          'progress': 0.0,
          'topics': ['System Design Basics', 'Live AI Interview Simulations', 'ATS Resume Tuning', 'HR Mock Rounds'],
        },
      ],
    },
    {
      'title': 'Flutter Mobile Architect',
      'icon': Icons.phone_android_rounded,
      'salary': '₹7 - 16 LPA',
      'jobs': '14,200+ Openings',
      'color': const Color(0xFF0EA5E9),
      'phases': [
        {
          'phase': 'Phase 1',
          'title': 'Dart Essentials & Flutter Widgets',
          'status': 'Completed',
          'progress': 1.0,
          'topics': ['Dart 3 Features', 'Stateless & Stateful Widgets', 'Layouts & Flex Box', 'Material 3 Design'],
        },
        {
          'phase': 'Phase 2',
          'title': 'Advanced State Management (Riverpod)',
          'status': 'In Progress',
          'progress': 0.40,
          'topics': ['StateNotifier & AsyncNotifier', 'Provider Scope & Dependency Injection', 'GoRouter Navigation'],
        },
        {
          'phase': 'Phase 3',
          'title': 'Native Integration & Backend APIs',
          'status': 'Locked',
          'progress': 0.0,
          'topics': ['REST & GraphQL', 'Method Channels', 'Local Storage (Hive / Isar)', 'Push Notifications'],
        },
        {
          'phase': 'Phase 4',
          'title': 'App Store Publishing & Testing',
          'status': 'Locked',
          'progress': 0.0,
          'topics': ['Unit & Widget Tests', 'CI/CD with Fastlane', 'Play Store & App Store Deployments'],
        },
      ],
    },
    {
      'title': 'AI & Data Science Specialist',
      'icon': Icons.psychology_rounded,
      'salary': '₹10 - 22 LPA',
      'jobs': '18,900+ Openings',
      'color': const Color(0xFF10B981),
      'phases': [
        {
          'phase': 'Phase 1',
          'title': 'Python & Exploratory Data Analysis',
          'status': 'Completed',
          'progress': 1.0,
          'topics': ['Python Syntax', 'NumPy & Pandas', 'Matplotlib & Seaborn', 'Data Wrangling'],
        },
        {
          'phase': 'Phase 2',
          'title': 'Machine Learning Algorithms',
          'status': 'In Progress',
          'progress': 0.20,
          'topics': ['Supervised Learning', 'Unsupervised Clustering', 'Scikit-Learn', 'Model Evaluation'],
        },
        {
          'phase': 'Phase 3',
          'title': 'Deep Learning & LLMs (GenAI)',
          'status': 'Locked',
          'progress': 0.0,
          'topics': ['Neural Networks (PyTorch)', 'Transformers & HuggingFace', 'LangChain & RAG', 'Prompt Engineering'],
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activePath = _paths[_selectedPathIndex];
    final accentColor = activePath['color'] as Color;
    final phases = activePath['phases'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.credDarkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.onSurface, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Career Roadmap Explorer',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Path Selector Chips
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _paths.length,
                itemBuilder: (context, i) {
                  final p = _paths[i];
                  final isSelected = i == _selectedPathIndex;
                  final color = p['color'] as Color;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPathIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : (isDark ? AppColors.credDarkCard : Colors.white),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : (isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0)),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(p['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : color),
                          const SizedBox(width: 8),
                          Text(
                            p['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : AppColors.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Header Banner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${phases.length} Learning Phases',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.work_outline_rounded, color: Colors.white, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              activePath['jobs'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activePath['title'] as String,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Target Package: ${activePath['salary']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Milestone Roadmap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline Steps List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: phases.length,
              itemBuilder: (context, index) {
                final ph = phases[index];
                final isLast = index == phases.length - 1;
                final status = ph['status'] as String;
                final progress = ph['progress'] as double;
                final topics = ph['topics'] as List<String>;

                Color statusColor;
                IconData statusIcon;
                if (status == 'Completed') {
                  statusColor = const Color(0xFF10B981);
                  statusIcon = Icons.check_circle_rounded;
                } else if (status == 'In Progress') {
                  statusColor = AppColors.primary;
                  statusIcon = Icons.play_circle_fill_rounded;
                } else if (status == 'Up Next') {
                  statusColor = const Color(0xFFF59E0B);
                  statusIcon = Icons.access_time_filled_rounded;
                } else {
                  statusColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
                  statusIcon = Icons.lock_rounded;
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Indicator Node
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: statusColor, width: 2),
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 16),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: statusColor.withValues(alpha: 0.3),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Card Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.credDarkCard : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: status == 'In Progress'
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                    : (isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
                                width: status == 'In Progress' ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ph['phase'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ph['title'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Progress bar if in progress or completed
                                if (progress > 0) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                      valueColor: AlwaysStoppedAnimation(statusColor),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Topics checklist
                                ...topics.map((t) => Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Row(
                                        children: [
                                          Icon(
                                            status == 'Completed'
                                                ? Icons.check_rounded
                                                : Icons.fiber_manual_record_rounded,
                                            size: 12,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              t,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? const Color(0xFF94A3B8)
                                                    : AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),

                                const SizedBox(height: 10),
                                // CTA Button for in progress phase
                                if (status == 'In Progress')
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      onPressed: () => context.push('/learn'),
                                      child: const Text('Continue Learning Phase',
                                          style: TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

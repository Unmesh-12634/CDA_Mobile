import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../profile/data/user_profile_provider.dart';
import '../../data/jobs_repository.dart';
import '../../data/mock_jobs.dart';
import '../../data/saved_jobs_provider.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _filterChips = [
    'All',
    'Remote',
    'Engineering',
    'Product',
    'Design',
    'Data',
    'AI/ML',
    'Full-time',
    'Internship',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Job> _filterJobList(List<Job> allJobs) {
    final q = _searchQuery.trim().toLowerCase();
    return allJobs.where((job) {
      final matchesCategory = _selectedCategory == 'All' ||
          (_selectedCategory == 'Remote' && job.location.toLowerCase().contains('remote')) ||
          (_selectedCategory == 'Full-time' && job.type.toLowerCase().contains('full')) ||
          (_selectedCategory == 'Internship' && job.type.toLowerCase().contains('intern')) ||
          (job.category.toLowerCase().contains(_selectedCategory.toLowerCase()));

      final matchesQuery = q.isEmpty ||
          job.title.toLowerCase().contains(q) ||
          job.company.toLowerCase().contains(q) ||
          job.description.toLowerCase().contains(q) ||
          job.tags.any((t) => t.toLowerCase().contains(q));

      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final userEmail = profile.email.isNotEmpty ? profile.email : ref.watch(authProvider).email;
    final realJobsAsync = ref.watch(realJobsListProvider(null));

    final rawJobs = realJobsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <Job>[],
    );
    final jobs = _filterJobList(rawJobs);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(realJobsListProvider(null));
            ref.invalidate(userApplicationsProvider(userEmail));
            ref.invalidate(appliedJobIdsProvider(userEmail));
            await ref.read(savedJobsProvider.notifier).loadSavedJobs();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Top App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo + Brand
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Center(
                              child: Text(
                                'CDA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Jobs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/application-tracker'),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.assignment_outlined, size: 15, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tracker',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => context.push('/saved-jobs'),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.bookmark_outline_rounded,
                                  size: 18, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Title + Search + Filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your next role',
                        style: AppTypography.displayMobile.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by title, skill, or company...',
                            hintStyle: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.outline.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.outline, size: 22),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded,
                                        color: isDark ? const Color(0xFF94A3B8) : AppColors.outline, size: 20),
                                    onPressed: () => setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    }),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _filterChips.map((chip) {
                            final isSelected = chip == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = chip),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : isDark ? const Color(0xFF334155) : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    chip,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : isDark ? const Color(0xFFCBD5E1) : AppColors.onSurfaceVariant,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Job Cards List
              jobs.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.work_off_rounded,
                                size: 56, color: isDark ? const Color(0xFF64748B) : AppColors.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No positions found',
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark ? Colors.white70 : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() {
                                _selectedCategory = 'All';
                                _searchQuery = '';
                                _searchController.clear();
                              }),
                              child: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final job = jobs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _JobCard(
                                job: job,
                                onTap: () => context.push('/jobs/${job.id}'),
                              ),
                            );
                          },
                          childCount: jobs.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  final Job job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final userEmail = profile.email.isNotEmpty ? profile.email : ref.watch(authProvider).email;

    final appliedSet = ref.watch(appliedJobIdsProvider(userEmail)).maybeWhen(
          data: (set) => set,
          orElse: () => <String>{},
        );
    final isApplied = appliedSet.contains(job.id);
    final isSaved = ref.watch(savedJobsProvider).contains(job.id);

    return _AppleSpringButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Logo + Bookmark + Match/Applied Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Company Logo Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                          : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      job.logoText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: isSaved ? AppColors.primary : (isDark ? const Color(0xFF94A3B8) : AppColors.outline),
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(savedJobsProvider.notifier).toggleSave(job.id);
                      },
                    ),
                    const SizedBox(width: 4),
                    if (isApplied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              'Applied ✓',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                          ),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${job.matchScore}% Match',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Title + Company
            Text(
              job.title,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.onSurface,
                height: 1.25,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              job.company,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Skill Tags Pill Row
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildSmallTag(context, job.type, isDark),
                _buildSmallTag(context, job.location, isDark),
                if (job.tags.isNotEmpty)
                  _buildSmallTag(context, job.tags.first, isDark),
              ],
            ),

            const SizedBox(height: 14),

            // Salary + Posted Time Row
            Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: 15, color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.salary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: isDark ? const Color(0xFF64748B) : AppColors.outline),
                    const SizedBox(width: 3),
                    Text(
                      job.postedAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF0F2)),
            const SizedBox(height: 12),

            // Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isApplied ? 'Application Under Review' : 'Quick Apply with Profile',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isApplied ? const Color(0xFF10B981) : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isApplied
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : (isDark
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.primary.withValues(alpha: 0.10)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isApplied ? 'Applied ✓' : 'View Role',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isApplied ? const Color(0xFF10B981) : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: isApplied ? const Color(0xFF10B981) : AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTag(BuildContext context, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AppleSpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AppleSpringButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_AppleSpringButton> createState() => _AppleSpringButtonState();
}

class _AppleSpringButtonState extends State<_AppleSpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _c, curve: Curves.fastOutSlowIn),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return GestureDetector(onTap: widget.onTap, child: widget.child);
    }
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../jobs/data/mock_jobs.dart';
import '../../../../shared/widgets/cda_gradient_footer.dart';

// ─────────────────────────────────────────────────────────────
// HOME SCREEN — Premium CDA Career Companion
// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // Trending skill selection
  int _selectedSkillIndex = 0;

  late AnimationController _heroAnim;
  late AnimationController _pulseAnim;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _pulse;

  // Animated search bar
  late AnimationController _searchAnim;
  bool _searchActive = false;
  final TextEditingController _searchTextCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();

  // ── Greeting helper ──────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _motivationalSubtitle {
    const subs = [
      'Keep learning. Your dream job is getting closer. 🚀',
      'You\'re one interview closer to your dream job. 💪',
      'Complete today\'s challenge. Stay consistent. 🎯',
      'Small steps every day lead to big careers. ⭐',
    ];
    return subs[DateTime.now().day % subs.length];
  }

  // ── Data ─────────────────────────────────────────────────
  final List<String> _skills = [
    'Java', 'Python', 'Flutter', 'React', 'Spring Boot',
    'AI', 'Machine Learning', 'Backend', 'Frontend',
    'Cloud', 'DevOps', 'Cyber Security', 'Data Science',
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.mic_rounded,
      'label': 'AI Readiness',
      'metric': '94%',
      'isFeatured': true,
      'route': '/interview/setup',
    },
    {
      'icon': Icons.psychology_rounded,
      'label': 'Practice Tests',
      'metric': '12',
      'isFeatured': false,
      'route': '/quiz',
    },
    {
      'icon': Icons.work_rounded,
      'label': 'Saved Jobs',
      'metric': '47',
      'isFeatured': false,
      'route': '/jobs',
    },
    {
      'icon': Icons.play_circle_fill_rounded,
      'label': 'Learning Reels',
      'metric': '234',
      'isFeatured': false,
      'route': '/learn',
    },
  ];

  final List<Map<String, dynamic>> _continueWatching = [
    {
      'title': 'System Design Masterclass',
      'mentor': 'Priya Sharma',
      'category': 'Backend',
      'duration': '22 min left',
      'progress': 0.65,
      'colorA': const Color(0xFF4648D4),
      'colorB': const Color(0xFF6B6EF9),
    },
    {
      'title': 'Flutter Advanced Patterns',
      'mentor': 'Rohan Mehta',
      'category': 'Mobile',
      'duration': '14 min left',
      'progress': 0.4,
      'colorA': const Color(0xFF0EA5E9),
      'colorB': const Color(0xFF38BDF8),
    },
    {
      'title': 'Data Science with Python',
      'mentor': 'Ananya Iyer',
      'category': 'AI/ML',
      'duration': '8 min left',
      'progress': 0.82,
      'colorA': const Color(0xFF10B981),
      'colorB': const Color(0xFF6EE7B7),
    },
  ];

  final List<Map<String, dynamic>> _recentActivity = [
    {
      'icon': Icons.mic_rounded,
      'color': const Color(0xFF4648D4),
      'title': 'Completed AI Interview',
      'sub': '2 hours ago • Score: 88%',
    },
    {
      'icon': Icons.play_circle_fill_rounded,
      'color': const Color(0xFF0EA5E9),
      'title': 'Watched Flutter Reel',
      'sub': 'Yesterday • 12 min',
    },
    {
      'icon': Icons.work_rounded,
      'color': const Color(0xFF10B981),
      'title': 'Saved Java Job at Google',
      'sub': '2 days ago',
    },
    {
      'icon': Icons.bookmark_rounded,
      'color': const Color(0xFFF59E0B),
      'title': 'Bookmarked AI Course',
      'sub': '3 days ago',
    },
    {
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFFEC4899),
      'title': 'Completed Daily Quiz',
      'sub': '4 days ago • 5/5 correct',
    },
  ];

  @override
  void initState() {
    super.initState();

    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseAnim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
        lowerBound: 0.95,
        upperBound: 1.05)
      ..repeat(reverse: true);

    _heroFade = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut));
    _pulse = _pulseAnim;
    _heroAnim.forward();

    _searchAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _pulseAnim.dispose();
    _searchAnim.dispose();
    _searchTextCtrl.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openSearchBar() {
    setState(() => _searchActive = true);
    _searchAnim.forward();
    Future.delayed(const Duration(milliseconds: 80), () {
      _searchFocus.requestFocus();
    });
  }

  void _closeSearchBar() {
    _searchFocus.unfocus();
    _searchAnim.reverse().then((_) {
      setState(() {
        _searchActive = false;
        _searchTextCtrl.clear();
      });
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — Coming Soon!'),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Search ──────────────────────────────────────────────
  void _openSearch() {
    final features = [
      {'icon': Icons.mic_rounded, 'label': 'AI Interview', 'route': '/interview/setup'},
      {'icon': Icons.work_rounded, 'label': 'Jobs', 'route': '/jobs'},
      {'icon': Icons.play_circle_fill_rounded, 'label': 'Learning Reels', 'route': '/learn'},
      {'icon': Icons.person_rounded, 'label': 'Profile', 'route': '/profile'},
      {'icon': Icons.psychology_rounded, 'label': 'Daily Quiz', 'route': '/quiz'},
    ];
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFDDE0E4), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setS(() => query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search features, jobs, skills...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(query.isEmpty ? 'Quick Navigate' : 'Results',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: features
                      .where((f) => query.isEmpty || (f['label'] as String).toLowerCase().contains(query))
                      .map((f) => ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(f['icon'] as IconData, color: AppColors.primary, size: 20),
                            ),
                            title: Text(f['label'] as String,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outlineVariant),
                            onTap: () {
                              Navigator.pop(ctx);
                              if (f['route'] != null) {
                                context.push(f['route'] as String);
                              } else {
                                _showComingSoon(f['label'] as String);
                              }
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Notifications ───────────────────────────────────────
  void _openNotifications() {
    final notifs = [
      {'icon': Icons.mic_rounded, 'color': AppColors.primary, 'title': 'New interview tip added', 'time': '2 min ago'},
      {'icon': Icons.work_rounded, 'color': const Color(0xFF10B981), 'title': 'Google posted a new Flutter role', 'time': '1 hr ago'},
      {'icon': Icons.star_rounded, 'color': const Color(0xFFF59E0B), 'title': 'You scored 88% in your last interview!', 'time': 'Yesterday'},
      {'icon': Icons.school_rounded, 'color': const Color(0xFF0EA5E9), 'title': 'New System Design reel available', 'time': '2 days ago'},
    ];
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? AppColors.credDarkBase : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: isDark ? AppColors.credDarkBorder : const Color(0xFFDDE0E4),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  const Text('Mark all read',
                      style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notifs.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF2F5)),
                itemBuilder: (_, i) {
                  final n = notifs[i];
                  return ListTile(
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                          color: (n['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 20),
                    ),
                    title: Text(n['title'] as String,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    subtitle: Text(n['time'] as String,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Settings ─────────────────────────────────────────────
  void _openSettings() {
    final items = [
      {'icon': Icons.person_rounded, 'label': 'Edit Profile', 'route': '/profile'},
      {'icon': Icons.notifications_rounded, 'label': 'Notification Preferences', 'route': null},
      {'icon': Icons.privacy_tip_rounded, 'label': 'Privacy & Security', 'route': null},
      {'icon': Icons.help_rounded, 'label': 'Help & Support', 'route': null},
      {'icon': Icons.info_rounded, 'label': 'About CDA', 'route': null},
    ];
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.credDarkBase : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? AppColors.credDarkBorder : const Color(0xFFDDE0E4),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                ),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                    ),
                    title: Text(item['label'] as String,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: isDark ? AppColors.credDarkBorder : AppColors.outlineVariant),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (item['route'] != null) {
                        context.push(item['route'] as String);
                      } else {
                        _showComingSoon(item['label'] as String);
                      }
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top App Bar ───────────────────────────────────
          SliverToBoxAdapter(child: _buildTopBar()),

          // ── Hero Banner ───────────────────────────────────
          SliverToBoxAdapter(child: _buildHero()),

          // ── Quick Actions 2×2 ─────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Quick Actions')),
          SliverToBoxAdapter(child: _buildQuickActions()),

          // ── Trending Skills ───────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Trending Skills')),
          SliverToBoxAdapter(child: _buildTrendingSkills()),

          // ── Continue Watching ─────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Continue Watching', actionLabel: 'See All', onAction: () => context.push('/learn'))),
          SliverToBoxAdapter(child: _buildContinueWatching()),

          // ── AI Interview Section ───────────────────────────
          SliverToBoxAdapter(child: _buildAIInterviewSection()),

          // ── Daily Quiz ────────────────────────────────────
          SliverToBoxAdapter(child: _buildDailyQuiz()),

          // ── Career Insights ───────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Career Insights', actionLabel: 'View All', onAction: () => context.push('/jobs'))),
          SliverToBoxAdapter(child: _buildCareerInsights()),

          // ── Learning Progress ─────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Your Progress')),
          SliverToBoxAdapter(child: _buildProgress()),

          // ── Recent Activity ───────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Recent Activity')),
          SliverToBoxAdapter(child: _buildRecentActivity()),

          // ── Recommended Jobs ──────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Recommended Openings', actionLabel: 'View All', onAction: () => context.push('/jobs'))),
          SliverToBoxAdapter(child: _buildRecommendedJobs()),

          // ── Footer divider spacing ────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Gradient Glow Footer ──────────────────────────
          SliverToBoxAdapter(
            child: CDAGradientFooter(
              scrollController: _scrollController,
              glowHeight: 180,
              minReveal: 0.05,
              bars: 9,
              child: const CDAHomeFooter(),
            ),
          ),

          // Nav bar clearance
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TOP APP BAR
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.credDarkBackground : Theme.of(context).scaffoldBackgroundColor;
    final searchBg = isDark ? const Color(0xFF111622) : const Color(0xFFF1F5F9);
    final searchBorder = isDark ? const Color(0xFF1E273A) : const Color(0xFFE2E8F0);
    final topPad = MediaQuery.of(context).padding.top + 10;

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: isDark
            ? const Border(bottom: BorderSide(color: AppColors.credDarkBorder, width: 0.5))
            : null,
      ),
      padding: EdgeInsets.only(
        top: topPad,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            // ── DEFAULT ROW: Avatar + Greeting + Icons ──────────────────
            AnimatedOpacity(
              opacity: _searchActive ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: _searchActive,
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('AV',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ),
                          ),
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.credDarkBackground : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$_greeting 👋',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500)),
                          Text('Arjun Verma',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.onSurface,
                                  height: 1.2)),
                        ],
                      ),
                    ),

                    // Search icon (opens animated search)
                    _TopIconBtn(icon: Icons.search_rounded, onTap: _openSearchBar),
                    const SizedBox(width: 6),

                    // Notifications with red badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _TopIconBtn(icon: Icons.notifications_none_rounded, onTap: _openNotifications),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.credDarkBackground : Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    _TopIconBtn(icon: Icons.settings_outlined, onTap: _openSettings),
                  ],
                ),
              ),
            ),

            // ── ANIMATED SEARCH BAR (slides in on top) ──────────────────
            AnimatedOpacity(
              opacity: _searchActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_searchActive,
                child: Row(
                  children: [
                    // Animated expanding search field
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: searchBorder, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchTextCtrl,
                                focusNode: _searchFocus,
                                autofocus: false,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppColors.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search courses, jobs, skills...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Close button
                    GestureDetector(
                      onTap: _closeSearchBar,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1E273A) : const Color(0xFFEEF0F4),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO BANNER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B3EC8), Color(0xFF5A5CF0), Color(0xFF7B7DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4648D4).withValues(alpha: 0.38),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Background circles decoration
                Positioned(
                  right: -30,
                  top: -30,
                  child: _AnimatedOrb(pulse: _pulse, size: 160, opacity: 0.08),
                ),
                Positioned(
                  right: 40,
                  bottom: -20,
                  child: _AnimatedOrb(pulse: _pulse, size: 100, opacity: 0.06),
                ),
                Positioned(
                  left: -20,
                  bottom: -40,
                  child: _AnimatedOrb(pulse: _pulse, size: 130, opacity: 0.05),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF34D399)),
                            ),
                            const SizedBox(width: 6),
                            const Text('3 Applications Active',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Big title
                      const Text(
                        'Ready for your\nnext opportunity?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _motivationalSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Buttons — CRED-style pill CTAs
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Primary CTA — white pill on the indigo hero
                          _HeroPrimaryBtn(
                            label: 'Start AI Interview',
                            icon: Icons.mic_rounded,
                            onTap: () => context.push('/interview/setup'),
                          ),
                          const SizedBox(height: 10),
                          // Secondary — frosted white ghost pill
                          _HeroGhostBtn(
                            label: 'Continue Learning',
                            icon: Icons.play_circle_outline_rounded,
                            onTap: () => context.push('/learn'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title,
      {String? actionLabel, VoidCallback? onAction}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.onSurface,
                  letterSpacing: -0.2)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF818CF8).withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(actionLabel,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // QUICK ACTIONS 2×2
  // ─────────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: _quickActions.length,
        itemBuilder: (context, i) {
          final a = _quickActions[i];
          return _QuickActionCard(
            icon: a['icon'] as IconData,
            label: a['label'] as String,
            metric: a['metric'] as String,
            isFeatured: a['isFeatured'] as bool,
            onTap: a['route'] != null
                ? () => context.push(a['route'] as String)
                : () => _showComingSoon(a['label'] as String),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TRENDING SKILLS chips
  // ─────────────────────────────────────────────────────────────
  Widget _buildTrendingSkills() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _skills.length,
        itemBuilder: (context, i) {
          final selected = i == _selectedSkillIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedSkillIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                color: selected
                    ? null
                    : (isDark ? AppColors.credDarkCard : Colors.white),
                borderRadius: BorderRadius.circular(100),
                border: selected
                    ? null
                    : Border.all(color: isDark ? AppColors.credDarkBorder : AppColors.outlineVariant),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  _skills[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CONTINUE WATCHING
  // ─────────────────────────────────────────────────────────────
  Widget _buildContinueWatching() {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _continueWatching.length,
        itemBuilder: (context, i) {
          final c = _continueWatching[i];
          return _WatchCard(
            title: c['title'] as String,
            mentor: c['mentor'] as String,
            category: c['category'] as String,
            duration: c['duration'] as String,
            progress: c['progress'] as double,
            colorA: c['colorA'] as Color,
            colorB: c['colorB'] as Color,
            onTap: () => context.push('/learn'),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AI INTERVIEW SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildAIInterviewSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.credDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B8C), Color(0xFF4648D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                // Icon orb
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Interview Practice',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'Practice real interviews with an adaptive AI interviewer.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                _StatPill(label: 'Last Score', value: '88%', icon: Icons.star_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                _StatPill(label: 'Streak', value: '5 days', icon: Icons.local_fire_department_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                _StatPill(label: 'Sessions', value: '12', icon: Icons.history_rounded, color: AppColors.secondary),
              ],
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _PillButton(
                    label: 'Start Interview',
                    filled: true,
                    onTap: () => context.push('/interview/setup'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PillButton(
                    label: 'Reports',
                    filled: false,
                    onTap: () => _showComingSoon('Reports'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DAILY QUIZ
  // ─────────────────────────────────────────────────────────────
  Widget _buildDailyQuiz() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F1508), const Color(0xFF2A1C0B)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF854D0E) : const Color(0xFFFEE3A0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + badge
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.credGoldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.credGold.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Skill Challenge',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))),
                      const SizedBox(height: 4),
                      Text('5 questions • 3 minutes',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.credGold,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('5 Questions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Description
            Text(
              'Test your knowledge with quick daily questions and build a streak!',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFFDE68A).withValues(alpha: 0.85) : const Color(0xFF92400E),
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            // Full-width button
            GestureDetector(
              onTap: () => context.push('/quiz'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: AppColors.credGoldGradient,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.credGold.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Start Today\'s Challenge',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CAREER INSIGHTS
  // ─────────────────────────────────────────────────────────────
  Widget _buildCareerInsights() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insights = [
      {'label': 'Recommended Jobs', 'count': '47', 'icon': Icons.work_rounded, 'color': AppColors.primary},
      {'label': 'Internships', 'count': '12', 'icon': Icons.school_rounded, 'color': const Color(0xFF10B981)},
      {'label': 'Companies Hiring', 'count': '23', 'icon': Icons.business_rounded, 'color': const Color(0xFF0EA5E9)},
      {'label': 'Upcoming Events', 'count': '5', 'icon': Icons.event_rounded, 'color': const Color(0xFFF59E0B)},
    ];
    return SizedBox(
      height: 128,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: insights.length,
        itemBuilder: (context, i) {
          final ins = insights[i];
          final color = ins['color'] as Color;
          return GestureDetector(
            onTap: () => context.push('/jobs'),
            child: Container(
              width: 142,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.credDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(ins['icon'] as IconData, color: color, size: 18),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ins['count'] as String,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: color,
                              height: 1.1)),
                      const SizedBox(height: 2),
                      Text(ins['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LEARNING PROGRESS
  // ─────────────────────────────────────────────────────────────
  Widget _buildProgress() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              _ProgressStat(label: 'Streak', value: '5 days', icon: Icons.local_fire_department_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              _ProgressStat(label: 'Avg Score', value: '84%', icon: Icons.star_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              _ProgressStat(label: 'Jobs Applied', value: '3', icon: Icons.work_rounded, color: const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _ProgressStat(label: 'Hrs Learned', value: '14h', icon: Icons.schedule_rounded, color: const Color(0xFF0EA5E9)),
            ],
          ),
          const SizedBox(height: 16),

          // Weekly progress bar
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.credDarkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weekly Learning Goal',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.onSurface)),
                    Text('3 / 5 days',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                // Day bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .asMap()
                      .entries
                      .map((e) {
                    final active = e.key < 3;
                    final heights = [0.9, 0.7, 1.0, 0.5, 0.4, 0.0, 0.0];
                    return Column(
                      children: [
                        Container(
                          width: 28,
                          height: 50,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : (isDark ? AppColors.credDarkSurface : const Color(0xFFF2F4F6)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: Duration(
                                  milliseconds: 600 + (e.key * 80)),
                              curve: Curves.easeOutCubic,
                              width: 28,
                              height: 50 * heights[e.key],
                              decoration: BoxDecoration(
                                gradient: active
                                    ? AppColors.primaryGradient
                                    : null,
                                color: active ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(e.value,
                            style: TextStyle(
                                fontSize: 10,
                                color: active
                                    ? AppColors.primary
                                    : (isDark ? const Color(0xFF64748B) : AppColors.outlineVariant),
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RECENT ACTIVITY
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.credDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: _recentActivity.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          final isLast = i == _recentActivity.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (a['color'] as Color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a['icon'] as IconData,
                          color: a['color'] as Color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title'] as String,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.onSurface)),
                          const SizedBox(height: 2),
                          Text(a['sub'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: isDark ? const Color(0xFF64748B) : AppColors.outlineVariant),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 66, color: isDark ? AppColors.credDarkBorder : const Color(0xFFF0F2F4)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RECOMMENDED JOBS (reuse mock data)
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecommendedJobs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featuredJobs = sampleJobs.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: featuredJobs.map((job) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => context.push('/jobs/${job.id}'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.credDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Company logo
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(job.logoText,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Job info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.onSurface)),
                          const SizedBox(height: 2),
                          Text(job.company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
                          const SizedBox(height: 5),
                          // Location only (salary removed to prevent overflow)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 11, color: isDark ? const Color(0xFF64748B) : AppColors.outline),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(job.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF64748B) : AppColors.outline)),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.payments_outlined,
                                  size: 11, color: isDark ? const Color(0xFF64748B) : AppColors.outline),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                    job.salary.split(' - ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF64748B) : AppColors.outline)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Match score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('${job.matchScore}%',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRIVATE COMPONENT WIDGETS
// ─────────────────────────────────────────────────────────────

class _AnimatedOrb extends AnimatedWidget {
  final double size;
  final double opacity;

  const _AnimatedOrb({
    required Animation<double> pulse,
    required this.size,
    required this.opacity,
  }) : super(listenable: pulse);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    return Transform.scale(
      scale: anim.value,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppColors.credDarkCard : Colors.white,
          shape: BoxShape.circle,
          border: isDark ? Border.all(color: AppColors.credDarkBorder) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 19, color: isDark ? Colors.white : AppColors.onSurfaceVariant),
      ),
    );
  }
}


class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String metric;
  final bool isFeatured;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.metric,
    required this.isFeatured,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFeatured = widget.isFeatured;

    // Colors matching user screenshots 2 & 3
    final cardBg = isFeatured
        ? null
        : (isDark ? AppColors.credDarkCard : Colors.white);
    final gradient = isFeatured
        ? const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final borderColor = isFeatured
        ? Colors.transparent
        : (isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2));

    final textColor = isFeatured
        ? Colors.white
        : (isDark ? Colors.white : AppColors.onSurface);
    final labelColor = isFeatured
        ? Colors.white.withValues(alpha: 0.85)
        : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant);

    final arrowBg = isFeatured
        ? Colors.white
        : (isDark ? const Color(0xFF1E273A) : const Color(0xFFF1F5F9));
    final arrowIconColor = isFeatured
        ? const Color(0xFF2563EB)
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isFeatured
                    ? const Color(0xFF2563EB).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: 3D/vibrant Icon + circular arrow pill (↗)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isFeatured
                          ? Colors.white.withValues(alpha: 0.2)
                          : (isDark
                              ? const Color(0xFF1E273A)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.icon,
                      color: isFeatured
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFF38BDF8)
                              : AppColors.primary),
                      size: 22,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: arrowBg,
                    ),
                    child: Icon(
                      Icons.north_east_rounded,
                      color: arrowIconColor,
                      size: 16,
                    ),
                  ),
                ],
              ),

              // Bottom column: metric label + BIG metric number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.metric,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchCard extends StatelessWidget {
  final String title;
  final String mentor;
  final String category;
  final String duration;
  final double progress;
  final Color colorA;
  final Color colorB;
  final VoidCallback onTap;

  const _WatchCard({
    required this.title,
    required this.mentor,
    required this.category,
    required this.duration,
    required this.progress,
    required this.colorA,
    required this.colorB,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.credDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorA, colorB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white.withValues(alpha: 0.8), size: 40),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(category,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: isDark ? AppColors.credDarkSurface : const Color(0xFFEEF0F2),
              valueColor: AlwaysStoppedAnimation<Color>(colorA),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.onSurface,
                          height: 1.3)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(mentor,
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
                      Text(duration,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatPill(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PillButton(
      {required this.label,
      required this.filled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          color: filled ? null : const Color(0xFFF2F4F6),
          borderRadius: BorderRadius.circular(100),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: filled ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProgressStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF0F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                    height: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Primary Button — crisp white pill over the indigo gradient ─────────
class _HeroPrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HeroPrimaryBtn({required this.label, required this.icon, required this.onTap});
  @override
  State<_HeroPrimaryBtn> createState() => _HeroPrimaryBtnState();
}
class _HeroPrimaryBtnState extends State<_HeroPrimaryBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _s = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.scale(
          scale: _s.value,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 17, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(widget.label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Ghost Button — frosted white ghost pill over the indigo gradient ───
class _HeroGhostBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HeroGhostBtn({required this.label, required this.icon, required this.onTap});
  @override
  State<_HeroGhostBtn> createState() => _HeroGhostBtnState();
}
class _HeroGhostBtnState extends State<_HeroGhostBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _s = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.scale(
          scale: _s.value,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 17, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

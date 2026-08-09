import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../jobs/data/mock_jobs.dart';
import '../../../subscription/data/subscription_provider.dart';
import '../../../subscription/presentation/widgets/cda_paywall_sheet.dart';
import '../../data/weekly_goal_provider.dart';
import '../../../profile/data/user_profile_provider.dart';

// ─────────────────────────────────────────────────────────────
// HOME SCREEN — Premium CDA Career Companion
// ─────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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
      'Keep learning. Your dream job is getting closer 🚀',
      'You\'re one interview closer to your dream job 💪',
      'Complete today\'s challenge. Stay consistent 🎯',
      'Small steps every day lead to big careers ⭐',
    ];
    return subs[DateTime.now().day % subs.length];
  }

  // ── Data ─────────────────────────────────────────────────
  final List<String> _skills = [
    'All', 'Java', 'Python', 'Flutter', 'React', 'Spring Boot',
    'AI', 'Machine Learning', 'Backend', 'Frontend',
    'Cloud', 'DevOps', 'Cyber Security', 'Data Science',
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.mic_rounded,
      'title': 'AI Interview',
      'subtitleKey': 'ai_trials',
      'color': const Color(0xFF6366F1), // Indigo accent
      'route': '/interview/setup',
    },
    {
      'icon': Icons.assignment_turned_in_rounded,
      'title': 'Job Tracker',
      'subtitle': '3 Active Apps',
      'color': const Color(0xFF10B981), // Emerald accent
      'route': '/applications',
    },
    {
      'icon': Icons.psychology_rounded,
      'title': 'Daily Challenge',
      'subtitle': '5 Qs • 200 XP',
      'color': const Color(0xFFF59E0B), // Amber Gold accent
      'route': '/quiz',
    },
    {
      'icon': Icons.explore_rounded,
      'title': 'Career Roadmap',
      'subtitle': 'Explore Paths',
      'color': const Color(0xFF0EA5E9), // Sapphire Blue accent
      'route': '/career-roadmap',
    },
  ];

  final List<Map<String, dynamic>> _recentActivity = [
    {
      'icon': Icons.mic_rounded,
      'color': const Color(0xFF4648D4),
      'title': 'Completed AI Interview',
      'sub': '2 hours ago • Score: 88%',
      'route': '/interview/analysis/rep-101',
    },
    {
      'icon': Icons.play_circle_fill_rounded,
      'color': const Color(0xFF0EA5E9),
      'title': 'Watched Flutter Reel',
      'sub': 'Yesterday • 12 min',
      'route': '/learn',
    },
    {
      'icon': Icons.work_rounded,
      'color': const Color(0xFF10B981),
      'title': 'Saved Java Job at Google',
      'sub': '2 days ago',
      'route': '/saved-jobs',
    },
    {
      'icon': Icons.bookmark_rounded,
      'color': const Color(0xFFF59E0B),
      'title': 'Bookmarked AI Course',
      'sub': '3 days ago',
      'route': '/learn',
    },
    {
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFFEC4899),
      'title': 'Completed Daily Quiz',
      'sub': '4 days ago • 5/5 correct',
      'route': '/quiz',
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



  // ── Notifications ───────────────────────────────────────
  void _openNotifications() {
    context.push('/notifications');
  }

  // ── Settings ─────────────────────────────────────────────
  void _openSettings() {
    final items = [
      {'icon': Icons.person_rounded, 'label': 'Edit Profile', 'route': '/edit-profile'},
      {'icon': Icons.notifications_rounded, 'label': 'Notification Preferences', 'action': _showNotificationPreferencesSheet},
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
                      if (item['action'] != null) {
                        (item['action'] as Function)();
                      } else if (item['route'] != null) {
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

  void _showNotificationPreferencesSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool pushAlerts = true;
    bool quizReminders = true;
    bool jobAlerts = true;
    bool interviewAlerts = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.credDarkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification Preferences',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Customize real-time alerts & reminders',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: pushAlerts,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: isDark ? Colors.white : AppColors.onSurface)),
                  subtitle: Text('Receive overall app activity updates', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
                  onChanged: (v) => setSheetState(() => pushAlerts = v),
                ),
                SwitchListTile.adaptive(
                  value: quizReminders,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Daily Quiz Reminders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: isDark ? Colors.white : AppColors.onSurface)),
                  subtitle: Text('Get notified for daily streak & XP questions', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
                  onChanged: (v) => setSheetState(() => quizReminders = v),
                ),
                SwitchListTile.adaptive(
                  value: jobAlerts,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Job Match Alerts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: isDark ? Colors.white : AppColors.onSurface)),
                  subtitle: Text('Alerts when high-match openings open', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
                  onChanged: (v) => setSheetState(() => jobAlerts = v),
                ),
                SwitchListTile.adaptive(
                  value: interviewAlerts,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text('AI Interview Feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: isDark ? Colors.white : AppColors.onSurface)),
                  subtitle: Text('Notifies when report evaluation is generated', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
                  onChanged: (v) => setSheetState(() => interviewAlerts = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notification preferences saved!'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Top App Bar ─────────────────────────────────
          SliverToBoxAdapter(child: _buildTopBar()),

          // ── 2. Hero Banner ─────────────────────────────────
          SliverToBoxAdapter(child: _buildHero()),

          // ── 3. Quick Access Hub 2×2 ────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Quick Access Hub')),
          SliverToBoxAdapter(child: _buildQuickActions()),

          // ── 4. Trending Skills Filter ──────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Trending Skills')),
          SliverToBoxAdapter(child: _buildTrendingSkills()),

          // ── 5. Recommended Openings ────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Recommended Openings', actionLabel: 'View All', onAction: () => context.push('/jobs'))),
          SliverToBoxAdapter(child: _buildRecommendedJobs()),

          // ── 6. AI Interview Section ────────────────────────
          SliverToBoxAdapter(child: _buildAIInterviewSection()),

          // ── 7. Daily Quiz ──────────────────────────────────
          SliverToBoxAdapter(child: _buildDailyQuiz()),

          // ── 8. Continue Watching ───────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Continue Watching', actionLabel: 'See All', onAction: () => context.push('/learn'))),
          SliverToBoxAdapter(child: _buildContinueWatching()),

          // ── 9. Career Insights ─────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Career Insights', actionLabel: 'View All', onAction: () => context.push('/jobs'))),
          SliverToBoxAdapter(child: _buildCareerInsights()),

          // ── 10. Learning Progress ──────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Your Progress')),
          SliverToBoxAdapter(child: _buildProgress()),

          // ── 11. Recent Activity ────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Recent Activity')),
          SliverToBoxAdapter(child: _buildRecentActivity()),

          // Nav bar clearance space — Dynamic responsive clearance
          SliverToBoxAdapter(
            child: SizedBox(
              height: 80 + MediaQuery.of(context).padding.bottom,
            ),
          ),
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
    final profile = ref.watch(userProfileProvider);

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
                            child: profile.avatarImagePath != null
                                ? ClipOval(
                                    child: kIsWeb
                                        ? Image.network(
                                            profile.avatarImagePath!,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(profile.avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                                            ),
                                          )
                                        : Image.file(
                                            File(profile.avatarImagePath!),
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(profile.avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                                            ),
                                          ),
                                  )
                                : Center(
                                    child: Text(profile.avatarInitials,
                                        style: const TextStyle(
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
                          Text(profile.name,
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
                      GestureDetector(
                        onTap: () => context.push('/applications'),
                        child: Container(
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
                            onTap: () => _launchAIInterview(),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
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

  void _launchAIInterview() {
    final sub = ref.read(subscriptionProvider);
    if (sub.isPremium) {
      context.push('/interview/setup');
      return;
    }

    if (sub.trialsRemaining > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '⚡ Free Trial Mode (${sub.trialsRemaining} of ${sub.totalFreeTrials} remaining)'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
      context.push('/interview/setup');
    } else {
      // Out of trials! Trigger paywall!
      CDAPaywallSheet.show(context);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // QUICK ACCESS HUB 2×2
  // ─────────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final sub = ref.watch(subscriptionProvider);
    final aiSubtitle = sub.isPremium
        ? 'PRO Unlimited 👑'
        : '${sub.trialsRemaining}/${sub.totalFreeTrials} Free Trials ⚡';

    Widget buildCard(Map<String, dynamic> a) {
      final isAI = a['route'] == '/interview/setup';
      final subTitle = isAI ? aiSubtitle : (a['subtitle'] as String);
      return Expanded(
        child: SizedBox(
          height: 112,
          child: _QuickAccessHubCard(
            icon: a['icon'] as IconData,
            title: a['title'] as String,
            subtitle: subTitle,
            accentColor: a['color'] as Color,
            onTap: isAI
                ? _launchAIInterview
                : (a['route'] != null
                    ? () => context.push(a['route'] as String)
                    : () => _showComingSoon(a['title'] as String)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              buildCard(_quickActions[0]),
              const SizedBox(width: 10),
              buildCard(_quickActions[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              buildCard(_quickActions[2]),
              const SizedBox(width: 10),
              buildCard(_quickActions[3]),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TRENDING SKILLS chips
  // ─────────────────────────────────────────────────────────────
  Widget _buildTrendingSkills() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _skills.length,
        itemBuilder: (context, i) {
          final selected = i == _selectedSkillIndex;
          return GestureDetector(
            onTap: () {
              if (_selectedSkillIndex != i) {
                setState(() => _selectedSkillIndex = i);
              }
            },
            child: AnimatedScale(
              scale: selected ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected
                      ? null
                      : (isDark ? AppColors.credDarkCard : Colors.white),
                  borderRadius: BorderRadius.circular(100),
                  border: selected
                      ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1)
                      : Border.all(
                          color: isDark ? AppColors.credDarkBorder : AppColors.outlineVariant),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.38),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        _skills[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String get _currentSkill => _skills[_selectedSkillIndex];

  List<Map<String, dynamic>> get _activeContinueWatching {
    final skill = _currentSkill;
    if (skill == 'All') {
      return [
        {
          'title': 'Java Multithreading & Concurrency',
          'mentor': 'Priya Sharma',
          'category': 'Java',
          'duration': '18 min left',
          'progress': 0.70,
          'colorA': const Color(0xFF4648D4),
          'colorB': const Color(0xFF6B6EF9),
        },
        {
          'title': 'Python for Data Structures & Algorithms',
          'mentor': 'Ananya Iyer',
          'category': 'Python',
          'duration': '12 min left',
          'progress': 0.85,
          'colorA': const Color(0xFF10B981),
          'colorB': const Color(0xFF6EE7B7),
        },
        {
          'title': 'Flutter Advanced State Management',
          'mentor': 'Rohan Mehta',
          'category': 'Flutter',
          'duration': '14 min left',
          'progress': 0.60,
          'colorA': const Color(0xFF0EA5E9),
          'colorB': const Color(0xFF38BDF8),
        },
        {
          'title': 'React 19 & Next.js App Router',
          'mentor': 'Karan Patel',
          'category': 'React',
          'duration': '15 min left',
          'progress': 0.75,
          'colorA': const Color(0xFF06B6D4),
          'colorB': const Color(0xFF67E8F9),
        },
      ];
    }
    if (skill == 'Java') {
      return [
        {
          'title': 'Java Multithreading & Concurrency',
          'mentor': 'Priya Sharma',
          'category': 'Java',
          'duration': '18 min left',
          'progress': 0.70,
          'colorA': const Color(0xFF4648D4),
          'colorB': const Color(0xFF6B6EF9),
        },
        {
          'title': 'Spring Boot Microservices Architecture',
          'mentor': 'Amit Kumar',
          'category': 'Java',
          'duration': '25 min left',
          'progress': 0.45,
          'colorA': const Color(0xFF0EA5E9),
          'colorB': const Color(0xFF38BDF8),
        },
      ];
    } else if (skill == 'Python') {
      return [
        {
          'title': 'Python for Data Structures & Algorithms',
          'mentor': 'Ananya Iyer',
          'category': 'Python',
          'duration': '12 min left',
          'progress': 0.85,
          'colorA': const Color(0xFF10B981),
          'colorB': const Color(0xFF6EE7B7),
        },
        {
          'title': 'FastAPI Production Backend Systems',
          'mentor': 'Vikram Singh',
          'category': 'Python',
          'duration': '30 min left',
          'progress': 0.30,
          'colorA': const Color(0xFFF59E0B),
          'colorB': const Color(0xFFFBBF24),
        },
      ];
    } else if (skill == 'Flutter') {
      return [
        {
          'title': 'Flutter Advanced State Management',
          'mentor': 'Rohan Mehta',
          'category': 'Flutter',
          'duration': '14 min left',
          'progress': 0.60,
          'colorA': const Color(0xFF0EA5E9),
          'colorB': const Color(0xFF38BDF8),
        },
        {
          'title': 'Riverpod & Clean Architecture',
          'mentor': 'Sneha Nair',
          'category': 'Flutter',
          'duration': '22 min left',
          'progress': 0.40,
          'colorA': const Color(0xFF6366F1),
          'colorB': const Color(0xFF818CF8),
        },
      ];
    } else if (skill == 'React') {
      return [
        {
          'title': 'React 19 & Next.js App Router',
          'mentor': 'Karan Patel',
          'category': 'React',
          'duration': '15 min left',
          'progress': 0.75,
          'colorA': const Color(0xFF06B6D4),
          'colorB': const Color(0xFF67E8F9),
        },
        {
          'title': 'TypeScript for Web Architecture',
          'mentor': 'Pooja Verma',
          'category': 'React',
          'duration': '28 min left',
          'progress': 0.50,
          'colorA': const Color(0xFF8B5CF6),
          'colorB': const Color(0xFFA78BFA),
        },
      ];
    }
    return [
      {
        'title': '$skill Core Principles & Deep Dive',
        'mentor': 'Cranes Senior Mentor',
        'category': skill,
        'duration': '20 min left',
        'progress': 0.65,
        'colorA': const Color(0xFF4648D4),
        'colorB': const Color(0xFF6063EE),
      },
      {
        'title': '$skill Technical Interview Prep',
        'mentor': 'Domain Expert',
        'category': 'Interview',
        'duration': '15 min left',
        'progress': 0.40,
        'colorA': const Color(0xFF10B981),
        'colorB': const Color(0xFF34D399),
      },
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // CONTINUE WATCHING
  // ─────────────────────────────────────────────────────────────
  Widget _buildContinueWatching() {
    final list = _activeContinueWatching;
    return SizedBox(
      key: ValueKey('continue_watching_$_selectedSkillIndex'),
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final c = list[i];
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
    final skill = _currentSkill;
    final skillLabel = skill == 'All' ? 'Tech' : skill;

    return Container(
      key: ValueKey('ai_interview_$skill'),
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
                      Text('Practice $skillLabel Interview',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'Practice real $skillLabel technical questions with an adaptive AI interviewer.',
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                _StatPill(label: 'Last Score', value: '88%', icon: Icons.star_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                _StatPill(label: 'Streak', value: '5 days', icon: Icons.local_fire_department_rounded, color: Colors.orange),
                SizedBox(width: 8),
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
                    label: 'Start $skillLabel Interview',
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
    final skill = _currentSkill;
    final skillLabel = skill == 'All' ? 'Daily Skill' : skill;

    return Container(
      key: ValueKey('daily_quiz_$skill'),
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
                      Text('$skillLabel Challenge',
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
                  child: Text('$skillLabel Quiz',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Description
            Text(
              'Test your $skillLabel knowledge with 5 quick daily questions and build a streak!',
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
    final skill = _currentSkill;
    final skillLabel = skill == 'All' ? 'Tech' : skill;
    final jobCount = 35 + (_selectedSkillIndex * 7) % 30;
    final internCount = 8 + (_selectedSkillIndex * 3) % 12;
    final companyCount = 18 + (_selectedSkillIndex * 5) % 20;

    final insights = [
      {'label': '$skillLabel Jobs', 'count': '$jobCount', 'icon': Icons.work_rounded, 'color': AppColors.primary},
      {'label': 'Internships', 'count': '$internCount', 'icon': Icons.school_rounded, 'color': const Color(0xFF10B981)},
      {'label': 'Companies Hiring', 'count': '$companyCount', 'icon': Icons.business_rounded, 'color': const Color(0xFF0EA5E9)},
      {'label': 'Upcoming Events', 'count': '5', 'icon': Icons.event_rounded, 'color': const Color(0xFFF59E0B)},
    ];
    return SizedBox(
      key: ValueKey('career_insights_$skill'),
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

  void _showProgressSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyGoal = ref.read(weeklyGoalProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.credDarkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Weekly Learning Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve studied ${weeklyGoal.totalHoursLearned} hours across ${weeklyGoal.completedDaysCount} active days this week. High consistency!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 20),
                  ),
                  title: Text('${weeklyGoal.streakCount}-Day Streak Active 🔥', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(weeklyGoal.nextGoalSuggestion, style: const TextStyle(fontSize: 12)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('84% Avg Interview Score ⭐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Top 10% in Java & System Design', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LEARNING PROGRESS
  // ─────────────────────────────────────────────────────────────
  Widget _buildProgress() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyGoal = ref.watch(weeklyGoalProvider);
    final todayIdx = DateTime.now().weekday - 1; // 0 = Mon, 6 = Sun
    final targetDays = weeklyGoal.targetDays;
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].take(targetDays).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              _ProgressStat(label: 'Streak', value: '${weeklyGoal.streakCount} days', icon: Icons.local_fire_department_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              const _ProgressStat(label: 'Avg Score', value: '84%', icon: Icons.star_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              const _ProgressStat(label: 'Jobs Applied', value: '3', icon: Icons.work_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              _ProgressStat(label: 'Hrs Learned', value: '${weeklyGoal.totalHoursLearned}h', icon: Icons.schedule_rounded, color: const Color(0xFF0EA5E9)),
            ],
          ),
          const SizedBox(height: 16),

          // Weekly progress analytics card
          GestureDetector(
            onTap: _showProgressSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.credDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.credDarkBorder : const Color(0xFFECEEF0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SECTION 1: HEADER ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Learning Goal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${weeklyGoal.completedDaysCount} / ${weeklyGoal.targetDays} Days',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED), // primary purple
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 2: MAIN ANALYTICS ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Side: Large Circular Progress Ring (Donut)
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Premium custom painted gradient donut progress
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DonutProgressPainter(
                                  progress: weeklyGoal.progressPercent,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            // Inside text and subtext
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${(weeklyGoal.progressPercent * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : AppColors.onSurface,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Goal Progress',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right Side: Three clean info rows
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              icon: '🎯',
                              title: 'Goal',
                              value: '${weeklyGoal.targetDays} Days per Week',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: '✅',
                              title: 'Completed',
                              value: '${weeklyGoal.completedDaysCount} Days',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: '🚀',
                              title: 'Next Goal',
                              value: weeklyGoal.nextGoalSuggestion,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── SECTION 3: WEEKLY TRACKER (Mon - Fri / Sat / Sun) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(targetDays, (index) {
                      final dayName = weekdays[index];
                      final isCompleted = weeklyGoal.completedDays[index];
                      final isCurrent = index == todayIdx;

                      Widget indicatorWidget;
                      if (isCompleted) {
                        // Completed: Filled purple circle with white check
                        indicatorWidget = Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF9061F9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        );
                      } else if (isCurrent) {
                        // Current: Outlined purple circle with day letter inside
                        indicatorWidget = Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                          ),
                          child: Center(
                            child: Text(
                              dayName[0],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Upcoming: Light grey outlined circle with day letter inside
                        indicatorWidget = Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF2A3C5D) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              dayName[0],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF64748B) : AppColors.outlineVariant,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                              color: isCurrent
                                  ? const Color(0xFF7C3AED)
                                  : (isDark ? const Color(0xFF64748B) : AppColors.outline),
                            ),
                          ),
                          const SizedBox(height: 6),
                          indicatorWidget,
                          const SizedBox(height: 4),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    Color bg;
    if (icon == '🎯') {
      bg = isDark ? const Color(0xFF3B244D) : const Color(0xFFFAE8FF);
    } else if (icon == '✅') {
      bg = isDark ? const Color(0xFF143F24) : const Color(0xFFDCFCE7);
    } else {
      bg = isDark ? const Color(0xFF2A1F4D) : const Color(0xFFEDE9FE);
    }

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(20) : Radius.zero,
                    bottom: isLast ? const Radius.circular(20) : Radius.zero,
                  ),
                  onTap: () {
                    if (a['route'] != null) {
                      context.push(a['route'] as String);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (a['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(a['icon'] as IconData,
                              color: a['color'] as Color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['title'] as String,
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.onSurface)),
                              const SizedBox(height: 3),
                              Text(a['sub'] as String,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: isDark ? const Color(0xFF64748B) : AppColors.outlineVariant),
                      ],
                    ),
                  ),
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
    final skill = _currentSkill;

    final matchingJobs = skill == 'All'
        ? sampleJobs.toList()
        : sampleJobs.where((j) =>
            j.title.toLowerCase().contains(skill.toLowerCase()) ||
            j.category.toLowerCase().contains(skill.toLowerCase()) ||
            j.tags.any((s) => s.toLowerCase().contains(skill.toLowerCase()))
          ).toList();

    final featuredJobs = matchingJobs.isNotEmpty
        ? matchingJobs.take(3).toList()
        : sampleJobs.take(3).toList();

    return Padding(
      key: ValueKey('recommended_jobs_$skill'),
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


// ─── QUICK ACCESS HUB CARD — Compact 2×2 Material 3 Card with Micro-Interactions
class _QuickAccessHubCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickAccessHubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_QuickAccessHubCard> createState() => _QuickAccessHubCardState();
}

class _QuickAccessHubCardState extends State<_QuickAccessHubCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _arrowSlide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _arrowSlide = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor;

    // Tinted gradient background for each card
    final cardGradient = isDark
        ? LinearGradient(
            colors: [
              accent.withValues(alpha: 0.16),
              const Color(0xFF131B2E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              accent.withValues(alpha: 0.08),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) {
        _anim.reverse();
        widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: cardGradient,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _anim.value > 0
                      ? accent.withValues(alpha: 0.7)
                      : (isDark
                          ? accent.withValues(alpha: 0.30)
                          : accent.withValues(alpha: 0.22)),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _anim.value > 0
                        ? accent.withValues(alpha: 0.30)
                        : (isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : accent.withValues(alpha: 0.08)),
                    blurRadius: _anim.value > 0 ? 6 : 14,
                    offset: _anim.value > 0
                        ? const Offset(0, 2)
                        : const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Premium Icon Badge + Rotatable Arrow Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Vibrant Solid Icon Badge
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent,
                              accent.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),

                      // Arrow Button Pill
                      Transform.translate(
                        offset: Offset(_arrowSlide.value, 0),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? accent.withValues(alpha: 0.15)
                                : accent.withValues(alpha: 0.10),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: isDark ? Colors.white : accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Column: Feature Name & Small Subtitle
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? accent.withValues(alpha: 0.14)
                                  : accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? accent.withValues(alpha: 0.95)
                                    : accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
    return AppleTactileCard(
      onTap: onTap,
      margin: const EdgeInsets.only(right: 14),
      backgroundColor: isDark ? AppColors.credDarkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: isDark ? AppColors.credDarkBorder : const Color(0xFFEEF0F2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 12,
        ),
      ],
      child: SizedBox(
        width: 210,
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

class _DonutProgressPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _DonutProgressPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // 1. Paint the background track
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2D4A) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Paint the active arc with gradient
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final activePaint = Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF7C3AED), // primary purple
            Color(0xFFC084FC), // light violet
            Color(0xFF7C3AED),
          ],
          stops: [0.0, 0.5, 1.0],
          transform: GradientRotation(-3.14159 / 2), // start at top
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -3.14159 / 2,
        2 * 3.14159 * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

// ─────────────────────────────────────────────────────────────
// APPLE DESIGN FOUNDATIONS & ANIMATION SKILLS
// Apple Spring Physics (Response: 0.2s, Damping: 1.0 Critically Damped)
// Reduced Motion Support & Zero-Latency Tactile Response
// ─────────────────────────────────────────────────────────────
class AppleTactileCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppleTactileCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.padding,
    this.margin,
  });

  @override
  State<AppleTactileCard> createState() => _AppleTactileCardState();
}

class _AppleTactileCardState extends State<AppleTactileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Apple Fluid Spring Parameters: Response 0.18s, Damping 1.0 (Critically Damped, No Overshoot)
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.fastOutSlowIn,
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    _springController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _springController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    _springController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final content = Container(
      padding: widget.padding,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
        border: widget.border,
        boxShadow: widget.boxShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return content;

    if (disableAnimations) {
      return GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: content,
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../subscription/data/subscription_provider.dart';
import '../../../subscription/presentation/widgets/cda_paywall_sheet.dart';
import '../../../auth/data/auth_provider.dart';
import '../../data/interview_setup_provider.dart';
import '../../data/ai_interview_service.dart';
import '../../data/interview_blocks_provider.dart';
import '../../../profile/data/user_profile_provider.dart';

// ─────────────────────────────────────────────────
// Models & Enums (100% Aligned with Backend main.py)
// ─────────────────────────────────────────────────
enum InterviewRole {
  java,
  fullstack,
  frontend,
  backend,
  python,
  aiMl,
  dataScience,
  dataAnalyst,
  devops,
  customRole,
}

enum InterviewType { technical, hr, behavioral, resumeBased, mixed }

enum InterviewDuration { short, standard, detailed }

// Candidate name and resume are loaded from the authenticated user — no hardcoding.

class InterviewSetupScreen extends ConsumerStatefulWidget {
  final int initialStep;
  const InterviewSetupScreen({super.key, this.initialStep = 0});

  @override
  ConsumerState<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends ConsumerState<InterviewSetupScreen>
    with TickerProviderStateMixin {
  late int _currentStep;
  InterviewRole? _selectedRole = InterviewRole.fullstack;
  final TextEditingController _customRoleCtrl = TextEditingController();

  InterviewTrack _selectedTrack = InterviewTrack.roleMock;
  String _selectedSkillDrill = 'Spring Boot Microservices';
  final TextEditingController _customJdTitleCtrl = TextEditingController(text: 'Senior Software Engineer');
  final TextEditingController _customJdCompanyCtrl = TextEditingController(text: 'Amazon / Top Tech');
  final TextEditingController _customJdDescCtrl = TextEditingController(text: 'Looking for a Senior Software Engineer with strong experience in Distributed Systems, Java, AWS, Microservices, and high-concurrency architecture.');
  String _selectedBehavioralScenario = 'Leadership & Ownership Under High Stakes';

  InterviewType? _selectedType = InterviewType.technical;
  double _difficulty = 2; // 1-Beginner, 2-Intermediate, 3-Advanced
  InterviewDuration _selectedDuration = InterviewDuration.standard;
  String _selectedModeId = 'comprehensive';
  String _selectedModeTitle = 'Comprehensive Round';
  final double _selectedSpeechRate = 0.50;
  final String _selectedVoicePersona = 'christopher'; // Default: Christopher — Executive Director
  String? _resumeFileName;

  late final PageController _pageController;
  late final AnimationController _progressAnim;
  late Animation<double> _progressValue;

  static const int _totalSteps = 5;

  final List<String> _stepNames = [
    'Role Selection',
    'Interview Type',
    'Difficulty & Duration',
    'Resume',
    'Ready to Go',
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, _totalSteps - 1);
    _pageController = PageController(initialPage: _currentStep);
    _progressAnim = AnimationController(
        vsync: this, duration: AppConstants.animationNormal);
    final initialProgress = (_currentStep + 1) / _totalSteps;
    _progressValue =
        Tween<double>(begin: initialProgress, end: initialProgress).animate(
            CurvedAnimation(
                parent: _progressAnim, curve: Curves.easeOutCubic));
    _progressAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ FIX 1: Write candidateName to provider immediately at setup open
      final authState = ref.read(authProvider);
      final realName = authState.fullName.trim().isNotEmpty
          ? authState.fullName.trim()
          : 'Candidate';
      ref.read(interviewSetupProvider.notifier).updateConfig(
        candidateName: realName,
      );
      ref.read(aiInterviewServiceProvider).preWarmBackend();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnim.dispose();
    _customRoleCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: AppConstants.animationNormal,
      curve: Curves.easeInOutCubic,
    );
    final newProgress = (step + 1) / _totalSteps;
    _progressValue = Tween<double>(
      begin: _progressValue.value,
      end: newProgress,
    ).animate(CurvedAnimation(
        parent: _progressAnim, curve: Curves.easeOutCubic));
    _progressAnim
      ..reset()
      ..forward();
  }

  void _selectAndAdvance(VoidCallback select) {
    select();
    Future.delayed(const Duration(milliseconds: 220), _nextStep);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) _goToStep(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  String get _roleLabel {
    final selectedBlock = ref.watch(interviewBlocksProvider).selectedBlock;
    if (selectedBlock != null) return selectedBlock.title;
    switch (_selectedRole) {
      case InterviewRole.java:
        return 'Java Developer';
      case InterviewRole.fullstack:
        return 'Full Stack Developer';
      case InterviewRole.frontend:
        return 'Frontend Developer';
      case InterviewRole.backend:
        return 'Backend Developer';
      case InterviewRole.python:
        return 'Python Developer';
      case InterviewRole.aiMl:
        return 'AI/ML Engineer';
      case InterviewRole.dataScience:
        return 'Data Scientist';
      case InterviewRole.dataAnalyst:
        return 'Data Analyst';
      case InterviewRole.devops:
        return 'DevOps Engineer';
      case InterviewRole.customRole:
        return _customRoleCtrl.text.isNotEmpty ? _customRoleCtrl.text : 'Custom Job Role';
      default:
        return 'Full Stack Developer';
    }
  }

  String get _typeLabel {
    switch (_selectedType) {
      case InterviewType.technical:
        return 'Technical';
      case InterviewType.hr:
        return 'HR';
      case InterviewType.behavioral:
        return 'Behavioral';
      case InterviewType.resumeBased:
        return 'Resume Based';
      case InterviewType.mixed:
        return 'Mixed';
      default:
        return 'Technical';
    }
  }

  String get _difficultyLabel {
    switch (_difficulty.round()) {
      case 1:
        return 'Beginner';
      case 3:
        return 'Advanced';
      default:
        return 'Intermediate';
    }
  }

  String get _experienceLevel {
    switch (_difficulty.round()) {
      case 1:
        return 'Entry-Level';
      case 3:
        return 'Senior';
      default:
        return 'Mid-Level';
    }
  }

  String get _difficultyDesc {
    switch (_difficulty.round()) {
      case 1:
        return 'Fundamental concepts, core syntax, basic problem-solving.';
      case 3:
        return 'High-scale architecture, trade-offs, concurrency & edge cases.';
      default:
        return 'Real-world practical implementation and system design patterns.';
    }
  }

  Color get _difficultyColor {
    switch (_difficulty.round()) {
      case 1:
        return const Color(0xFF2E7D32);
      case 3:
        return const Color(0xFFB75E00);
      default:
        return AppColors.primary;
    }
  }

  IconData get _difficultyIcon {
    switch (_difficulty.round()) {
      case 1:
        return Icons.school_rounded;
      case 3:
        return Icons.military_tech_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  String get _durationMinutesLabel {
    switch (_selectedDuration) {
      case InterviewDuration.short:
        return '15';
      case InterviewDuration.detailed:
        return '45';
      default:
        return '25';
    }
  }

  String get _durationNameLabel {
    switch (_selectedDuration) {
      case InterviewDuration.short:
        return 'Short Round';
      case InterviewDuration.detailed:
        return 'Detailed Round';
      default:
        return 'Standard Round';
    }
  }

  int get _targetQuestionCount {
    switch (_selectedDuration) {
      case InterviewDuration.short:
        return 3;
      case InterviewDuration.detailed:
        return 8;
      default:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : cs.surface,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.credDarkBackground : cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: cs.onSurface),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'AI Interview Setup',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar & Step Name Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.marginMobile, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP ${_currentStep + 1} OF $_totalSteps',
                        style: AppTypography.codeMono.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                      Text(
                        _stepNames[_currentStep],
                        style: AppTypography.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: _progressValue.value,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View with Step Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Role(cs),
                  _buildStep2Type(cs),
                  _buildStep3DiffDuration(cs),
                  _buildStep4Resume(cs),
                  _buildStep5Summary(cs),
                ],
              ),
            ),

            // Bottom Navigation Footer
            _buildBottomFooter(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomFooter(ColorScheme cs) {
    final isTapAdvanceStep = _currentStep == 0 || _currentStep == 1;
    final isLast = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(AppConstants.marginMobile),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                onPressed: _prevStep,
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Back',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (!isTapAdvanceStep && !isLast)
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  onPressed: _nextStep,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            if (isTapAdvanceStep)
              Expanded(
                child: Center(
                  child: Text(
                    _currentStep == 0
                        ? '✨ Tap a role to continue'
                        : '✨ Tap a type to continue',
                    style: AppTypography.bodySmall.copyWith(
                        color: cs.outline,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STEP 1 — JD Grid (2 columns, DB blocks + fallback)
  // ─────────────────────────────────────────────────────────

  /// Returns a consistent accent color per block based on title keywords
  Color _accentForBlock(InterviewBlockModel block) {
    final t = block.title.toLowerCase();
    if (t.contains('java'))     return const Color(0xFFE76F00);
    if (t.contains('python'))   return const Color(0xFF3572A5);
    if (t.contains('flutter') || t.contains('mobile')) return const Color(0xFF54C5F8);
    if (t.contains('react') || t.contains('frontend') || t.contains('next')) return const Color(0xFF61DAFB);
    if (t.contains('ai') || t.contains('ml') || t.contains('data science')) return const Color(0xFF10B981);
    if (t.contains('devops') || t.contains('cloud') || t.contains('aws') || t.contains('kubernetes')) return const Color(0xFFFF9900);
    if (t.contains('data') || t.contains('analyst')) return const Color(0xFF906BD8);
    if (t.contains('full') || t.contains('stack')) return const Color(0xFF0F2088);
    if (t.contains('backend') || t.contains('node') || t.contains('go')) return const Color(0xFF0F2088);
    return AppColors.primary;
  }

  Widget _buildStep1Role(ColorScheme cs) {
    final blocksState = ref.watch(interviewBlocksProvider);
    final blocksNotifier = ref.read(interviewBlocksProvider.notifier);

    final allBlocks = blocksState.blocks.isNotEmpty
        ? blocksState.blocks
        : defaultFallbackBlocks;

    final selectedId = blocksState.selectedBlock?.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Interview Setup',
                      style: AppTypography.headlineMobile.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose your personalized interview track',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedTrack == InterviewTrack.roleMock)
                GestureDetector(
                  onTap: () => _showAddJdDialog(context, blocksNotifier),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          'Add JD',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Track Selector Tabs (5 Tracks) ─────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTrackTab(
                  label: '🏢 Role Mock',
                  track: InterviewTrack.roleMock,
                  cs: cs,
                ),
                const SizedBox(width: 8),
                _buildTrackTab(
                  label: '🎯 Skill Drill',
                  track: InterviewTrack.skillDrill,
                  cs: cs,
                ),
                const SizedBox(width: 8),
                _buildTrackTab(
                  label: '📄 Custom JD',
                  track: InterviewTrack.customJd,
                  cs: cs,
                ),
                const SizedBox(width: 8),
                _buildTrackTab(
                  label: '👤 Resume Profile',
                  track: InterviewTrack.resumeBased,
                  cs: cs,
                ),
                const SizedBox(width: 8),
                _buildTrackTab(
                  label: '🌟 STAR Behavioral',
                  track: InterviewTrack.behavioralStar,
                  cs: cs,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Dynamic View Based on Selected Track ───────────
          if (_selectedTrack == InterviewTrack.roleMock)
            _buildRoleMockView(cs, allBlocks, selectedId, blocksNotifier)
          else if (_selectedTrack == InterviewTrack.skillDrill)
            _buildSkillDrillView(cs)
          else if (_selectedTrack == InterviewTrack.customJd)
            _buildCustomJdView(cs)
          else if (_selectedTrack == InterviewTrack.resumeBased)
            _buildResumeProfileView(cs)
          else if (_selectedTrack == InterviewTrack.behavioralStar)
            _buildBehavioralStarView(cs),
        ],
      ),
    );
  }

  Widget _buildTrackTab({
    required String label,
    required InterviewTrack track,
    required ColorScheme cs,
  }) {
    final isSelected = _selectedTrack == track;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTrack = track);
        ref.read(interviewSetupProvider.notifier).updateConfig(track: track);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : cs.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.black : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleMockView(
    ColorScheme cs,
    List<InterviewBlockModel> allBlocks,
    String? selectedId,
    InterviewBlocksNotifier blocksNotifier,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: allBlocks.length,
      itemBuilder: (context, index) {
        final block = allBlocks[index];
        final isSelected = selectedId == block.id;
        final accent = _accentForBlock(block);

        return _buildJdGridCard(
          cs: cs,
          block: block,
          isSelected: isSelected,
          accent: accent,
          onTap: () {
            setState(() => _selectedRole = InterviewRole.customRole);
            blocksNotifier.selectBlock(block);
            ref.read(interviewSetupProvider.notifier).updateConfig(
              track: InterviewTrack.roleMock,
              jobRole: block.title,
              jobDescriptionText: block.description,
              jobRequiredSkills: block.requiredSkills,
              skills: block.requiredSkills,
              difficulty: block.difficulty.isNotEmpty ? block.difficulty : _difficultyLabel,
              experienceLevel: block.experienceLevel.isNotEmpty ? block.experienceLevel : _experienceLevel,
              interviewType: block.interviewType.isNotEmpty ? block.interviewType : _typeLabel,
              targetQuestionCount: block.targetQuestionCount > 0 ? block.targetQuestionCount : _targetQuestionCount,
            );
            _nextStep();
          },
        );
      },
    );
  }

  Widget _buildSkillDrillView(ColorScheme cs) {
    final skills = [
      {'name': 'Spring Boot Microservices', 'icon': Icons.bolt_rounded, 'color': const Color(0xFF6DB33F), 'desc': 'REST APIs, Actuator, Security & JPA'},
      {'name': 'Java Concurrency & Threads', 'icon': Icons.tune_rounded, 'color': const Color(0xFFE76F00), 'desc': 'Executors, Locks, Volatile & ForkJoin'},
      {'name': 'Flutter & State Management', 'icon': Icons.phone_android_rounded, 'color': const Color(0xFF54C5F8), 'desc': 'Riverpod, AsyncValue & Widget Lifecycle'},
      {'name': 'PostgreSQL & Query Tuning', 'icon': Icons.storage_rounded, 'color': const Color(0xFF336791), 'desc': 'B-Tree, EXPLAIN ANALYZE & Transactions'},
      {'name': 'Data Structures & Algorithms', 'icon': Icons.psychology_rounded, 'color': const Color(0xFF10B981), 'desc': 'Trees, Graphs, DP & Time Complexity'},
      {'name': 'System Design & Distributed Systems', 'icon': Icons.lan_rounded, 'color': const Color(0xFF8B5CF6), 'desc': 'Load Balancing, Caching, CAP & Sharding'},
      {'name': 'Python, FastAPI & AI RAG', 'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFFF59E0B), 'desc': 'LangChain, Vector DBs & Embeddings'},
      {'name': 'Docker, Kubernetes & CI/CD', 'icon': Icons.cloud_done_rounded, 'color': const Color(0xFF0EA5E9), 'desc': 'Containers, Pods, Helm & Pipelines'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Technical Competency',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: skills.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = skills[index];
            final name = s['name'] as String;
            final icon = s['icon'] as IconData;
            final color = s['color'] as Color;
            final desc = s['desc'] as String;
            final isSelected = _selectedSkillDrill == name;

            return _buildUniversalOptionCard(
              title: name,
              subtitle: desc,
              icon: icon,
              color: color,
              isSelected: isSelected,
              badge: 'SKILL DRILL',
              onTap: () {
                setState(() => _selectedSkillDrill = name);
                ref.read(interviewSetupProvider.notifier).updateConfig(
                  track: InterviewTrack.skillDrill,
                  jobRole: 'Skill Drill: $name',
                  skills: [name],
                  interviewType: 'Technical',
                  jobDescriptionText: 'Deep-dive technical competency drill focusing strictly on $name.',
                );
                _nextStep();
              },
              cs: cs,
            );
          },
        ),
      ],
    );
  }

  Widget _buildUniversalOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    String? badge,
    List<String>? tags,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : cs.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : cs.onSurface,
                          ),
                        ),
                      ),
                      if (badge != null && badge.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.3),
                  ),
                  if (tags != null && tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.take(4).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomJdView(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Role & Company',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _customJdTitleCtrl,
          decoration: InputDecoration(
            labelText: 'Target Job Title',
            hintText: 'e.g. SDE-2 Java & Distributed Systems',
            prefixIcon: const Icon(Icons.work_outline_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _customJdCompanyCtrl,
          decoration: InputDecoration(
            labelText: 'Company Name',
            hintText: 'e.g. Amazon, Google, Swiggy, TCS',
            prefixIcon: const Icon(Icons.business_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Paste Job Description (JD)',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _customJdDescCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Paste the requirements, tech stack, and responsibilities...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Start Custom JD Interview', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              final title = _customJdTitleCtrl.text.trim().isNotEmpty ? _customJdTitleCtrl.text.trim() : 'Custom Role';
              final company = _customJdCompanyCtrl.text.trim();
              final desc = _customJdDescCtrl.text.trim();

              ref.read(interviewSetupProvider.notifier).updateConfig(
                track: InterviewTrack.customJd,
                jobRole: company.isNotEmpty ? '$title @ $company' : title,
                jobDescriptionText: desc,
                targetCompany: company,
                interviewType: 'Technical',
              );
              _nextStep();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResumeProfileView(ColorScheme cs) {
    final profile = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name.isNotEmpty ? profile.name : 'Candidate Profile',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          profile.targetRole.isNotEmpty ? profile.targetRole : 'Full Stack Developer',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Detected Profile Skills:',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (profile.skills.isNotEmpty ? profile.skills : ['Java', 'Flutter', 'Spring Boot', 'SQL', 'Git'])
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Academic / Project Focus:',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                profile.degree.isNotEmpty
                    ? '${profile.degree} ${profile.branch.isNotEmpty ? "- ${profile.branch}" : ""} (${profile.yearOfPassing})'
                    : 'Computer Science & Engineering',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.psychology_rounded),
            label: const Text('Start Profile-Personalized Interview', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              ref.read(interviewSetupProvider.notifier).updateConfig(
                track: InterviewTrack.resumeBased,
                candidateName: profile.name,
                jobRole: profile.targetRole.isNotEmpty ? profile.targetRole : 'Full Stack Developer',
                skills: profile.skills.isNotEmpty ? profile.skills : ['Java', 'Flutter', 'Spring Boot'],
                interviewType: 'Resume Based',
                jobDescriptionText: 'Personalized interview probing candidate actual resume projects, academic coursework, and tech stack.',
              );
              _nextStep();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBehavioralStarView(ColorScheme cs) {
    final scenarios = [
      {
        'title': 'Leadership & High-Stakes Ownership',
        'desc': 'Tell me about a time you took ownership of a critical project under ambiguous requirements.',
        'icon': Icons.military_tech_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Cross-Functional & Engineer Conflict',
        'desc': 'Describe a situation where you strongly disagreed with a senior engineer or product manager.',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Urgent Outage & High-Pressure Delivery',
        'desc': 'Tell me about a production incident or tight deadline and how you prioritized under pressure.',
        'icon': Icons.speed_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Technical Trade-off & Architectural Pivot',
        'desc': 'Give an example of choosing speed to market over architectural purity, and the consequences.',
        'icon': Icons.architecture_rounded,
        'color': const Color(0xFF10B981),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'STAR Method: Situation → Task → Action → Result. Answer with specific personal metrics!',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: scenarios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final sc = scenarios[index];
            final title = sc['title'] as String;
            final desc = sc['desc'] as String;
            final icon = sc['icon'] as IconData;
            final color = sc['color'] as Color;
            final isSelected = _selectedBehavioralScenario == title;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedBehavioralScenario = title);
                ref.read(interviewSetupProvider.notifier).updateConfig(
                  track: InterviewTrack.behavioralStar,
                  jobRole: 'STAR Behavioral: $title',
                  interviewType: 'Behavioral',
                  jobDescriptionText: desc,
                );
                _nextStep();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
      ],
    );
  }

  Widget _buildJdGridCard({
    required ColorScheme cs,
    required InterviewBlockModel block,
    required bool isSelected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.12)
              : cs.surfaceContainerLow.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : cs.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Domain Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isSelected ? 0.22 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(block.iconData, color: accent, size: 20),
            ),
            const SizedBox(width: 10),

            // Domain Name & Details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? accent : cs.onSurface,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    block.badgeTag.toUpperCase(),
                    style: AppTypography.codeMono.copyWith(
                      color: isSelected ? accent : cs.outline,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selection Check Circle
            if (isSelected)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
                child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }




  void _showAddJdDialog(BuildContext context, InterviewBlocksNotifier notifier) {
    final titleCtrl = TextEditingController();
    final companyCtrl = TextEditingController(text: 'Cranes Varsity');
    final descCtrl = TextEditingController();
    final skillsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.post_add_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Create New JD Track', style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Job Title (e.g. Flutter Engineer)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tech Requirements & Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Required Skills (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
                final skills = skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final newBlock = InterviewBlockModel(
                  id: '',
                  title: titleCtrl.text.trim(),
                  companyName: companyCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  requiredSkills: skills,
                  badgeTag: 'NEW JD',
                  iconName: 'code',
                );
                await notifier.addNewBlock(newBlock);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save & Create Block'),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // STEP 2 — Interview Type
  // ─────────────────────────────────────────────────────────
  Widget _buildStep2Type(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Interview Format',
              style: AppTypography.headlineMobile
                  .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text('Choose the focus area for your session',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildTypeCard(
                    InterviewType.technical,
                    Icons.code_rounded,
                    'Technical Screening',
                    'Algorithms, data structures & live problem solving',
                    AppColors.primary,
                    cs),
                const SizedBox(height: 12),
                _buildTypeCard(
                    InterviewType.behavioral,
                    Icons.psychology_rounded,
                    'Behavioral & STAR',
                    'Leadership, conflict resolution & teamwork',
                    AppColors.secondary,
                    cs),
                const SizedBox(height: 12),
                _buildTypeCard(
                    InterviewType.resumeBased,
                    Icons.assignment_ind_rounded,
                    'Resume Deep-Dive',
                    'Project architecture & past work verification',
                    AppColors.tertiary,
                    cs),
                const SizedBox(height: 12),
                _buildTypeCard(
                    InterviewType.hr,
                    Icons.people_alt_rounded,
                    'HR & Culture Fit',
                    'Career goals, motivation & role expectations',
                    const Color(0xFF10B981),
                    cs),
                const SizedBox(height: 12),
                _buildTypeCard(
                    InterviewType.mixed,
                    Icons.auto_awesome_rounded,
                    'Comprehensive Mixed Round',
                    'Balanced mix of technical, architecture & behavioral',
                    const Color(0xFF8B5CF6),
                    cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(InterviewType type, IconData icon, String title,
      String subtitle, Color color, ColorScheme cs) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => _selectAndAdvance(() {
        setState(() => _selectedType = type);
        // ✅ FIX 3: Sync interview type to provider immediately
        ref.read(interviewSetupProvider.notifier).updateConfig(
          interviewType: title.contains('Technical') ? 'Technical'
            : title.contains('Behavioral') ? 'Behavioral'
            : title.contains('Resume') ? 'Resume Based'
            : title.contains('HR') ? 'HR'
            : 'Mixed',
        );
      }),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.07) : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? color : cs.outlineVariant,
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STEP 3 — Difficulty, Rigor Mode & Session Duration
  // ─────────────────────────────────────────────────────────
  Widget _buildStep3DiffDuration(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionChip(Icons.tune_rounded, 'INTERVIEW MODE & RIGOR', AppColors.primary),
          const SizedBox(height: 14),

          // 4 Interactive Mode Cards
          Column(
            children: [
              _buildModeCard(
                id: 'comprehensive',
                title: 'Comprehensive Round',
                subtitle: '5 Questions • Balanced technical depth, system design, and coding trade-offs.',
                badge: 'BALANCED',
                icon: Icons.layers_rounded,
                color: const Color(0xFF0284C7),
                qCount: 5,
                cs: cs,
              ),
              const SizedBox(height: 10),
              _buildModeCard(
                id: 'hard_mode',
                title: 'Hard Mode (Senior Staff Probing)',
                subtitle: '7 Questions • Deep edge-case stress testing & strict performance evaluations.',
                badge: 'STRICT PROBING',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEF4444),
                qCount: 7,
                cs: cs,
              ),
              const SizedBox(height: 10),
              _buildModeCard(
                id: 'rapid_fire',
                title: 'Rapid Fire Mode',
                subtitle: '3 Questions • Fast 60-second diagnostic sprint testing instant recall.',
                badge: 'RAPID SPRINT',
                icon: Icons.bolt_rounded,
                color: const Color(0xFFF59E0B),
                qCount: 3,
                cs: cs,
              ),
              const SizedBox(height: 10),
              _buildModeCard(
                id: 'hr_behavioral',
                title: 'HR & Behavioral Round',
                subtitle: '5 Questions • STAR framework, situational leadership, and Cranes career readiness.',
                badge: 'HR / STAR',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF10B981),
                qCount: 5,
                cs: cs,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Evaluation Matrix Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'DATABASE EVALUATION MATRIX',
                      style: AppTypography.codeMono.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Technical Depth 35% · Edge Cases 25% · Keywords 20% · Communication 20%',
                  style: AppTypography.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionChip(Icons.bar_chart_rounded, 'CHALLENGE LEVEL', AppColors.primary),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _buildDiffCard(1, 'Beginner', Icons.school_rounded,
                  'Entry concepts', const Color(0xFF2E7D32), cs)),
              const SizedBox(width: 10),
              Expanded(child: _buildDiffCard(2, 'Intermediate', Icons.workspace_premium_rounded,
                  'Real patterns', AppColors.primary, cs)),
              const SizedBox(width: 10),
              Expanded(child: _buildDiffCard(3, 'Advanced', Icons.military_tech_rounded,
                  'Senior expertise', const Color(0xFFB75E00), cs)),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _difficultyColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _difficultyColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(_difficultyIcon, color: _difficultyColor, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _difficultyDesc,
                    style: AppTypography.bodySmall.copyWith(
                        color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSectionChip(Icons.timer_rounded, 'SESSION DURATION', AppColors.secondary),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                  child: _buildDurationCard(
                      InterviewDuration.short, '15', 'Short Round', '3–5 questions', Icons.flash_on_rounded, cs)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildDurationCard(
                      InterviewDuration.standard, '25', 'Standard Round', '5–8 questions', Icons.schedule_rounded, cs)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildDurationCard(
                      InterviewDuration.detailed, '45', 'Detailed Round', '8–12 questions', Icons.psychology_rounded, cs)),
            ],
          ),

          const SizedBox(height: 16),

          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.secondary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configured for $_selectedModeTitle ($_targetQuestionCount Questions) at $_difficultyLabel level.',
                    style: AppTypography.bodySmall.copyWith(
                        color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String id,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color color,
    required int qCount,
    required ColorScheme cs,
  }) {
    final isSelected = _selectedModeId == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedModeId = id;
          _selectedModeTitle = title;
        });
        ref.read(interviewSetupProvider.notifier).updateConfig(
          modeId: id,
          modeDisplayName: title,
          targetQuestionCount: qCount,
        );
      },
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
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

  Widget _buildSectionChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.codeMono.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildDiffCard(int level, String label, IconData icon,
      String subtitle, Color color, ColorScheme cs) {
    final isSelected = _difficulty.round() == level;
    return GestureDetector(
      onTap: () {
        setState(() => _difficulty = level.toDouble());
        // ✅ FIX 4a: Sync difficulty + experience to provider on tap
        final diffLabel = level == 1 ? 'Beginner' : level == 3 ? 'Advanced' : 'Intermediate';
        final expLabel = level == 1 ? 'Entry-Level' : level == 3 ? 'Senior' : 'Mid-Level';
        ref.read(interviewSetupProvider.notifier).updateConfig(
          difficulty: diffLabel,
          experienceLevel: expLabel,
        );
      },
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? color : cs.outlineVariant,
              width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : cs.outline, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isSelected ? color : cs.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard(InterviewDuration duration, String minutes,
      String label, String qCount, IconData icon, ColorScheme cs) {
    final isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDuration = duration);
        // ✅ FIX 4b: Sync target question count to provider on duration tap
        final count = duration == InterviewDuration.short ? 3
            : duration == InterviewDuration.detailed ? 8 : 5;
        ref.read(interviewSetupProvider.notifier).updateConfig(
          targetQuestionCount: count,
        );
      },
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.primary : cs.outlineVariant,
              width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.primary : cs.outline,
                size: 20),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(minutes,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.primary
                            : cs.onSurface)),
                const SizedBox(width: 2),
                Text('MIN',
                    style: AppTypography.codeMono.copyWith(
                        fontSize: 8,
                        color: isSelected ? AppColors.primary : cs.outline,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : cs.onSurface,
                    fontSize: 10)),
            const SizedBox(height: 2),
            Text(qCount,
                style: AppTypography.codeMono
                    .copyWith(fontSize: 8, color: cs.outline),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STEP 4 — Resume
  // ─────────────────────────────────────────────────────────
  bool _isAnalyzingResume = false;
  List<String> _parsedResumeSkills = [];
  List<String> _parsedResumeProjects = [];
  List<String> _parsedResumeHackathons = [];
  List<String> _parsedResumeCertifications = [];

  Widget _buildStep4Resume(ColorScheme cs) {
    final hasParsedData = _parsedResumeSkills.isNotEmpty ||
        _parsedResumeProjects.isNotEmpty ||
        _parsedResumeHackathons.isNotEmpty ||
        _parsedResumeCertifications.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your resume',
              style: AppTypography.headlineMobile
                  .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text(
            'Upload your PDF resume so AI parses your skills, projects, hackathons, and certifications upfront.',
            style: AppTypography.bodyMedium
                .copyWith(color: cs.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 20),

          GlassCard(
            backgroundColor: AppColors.primary.withValues(alpha: 0.04),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resumeFileName ?? 'No resume uploaded',
                        style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold, color: cs.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PDF Document · Tap to change & analyze',
                        style: AppTypography.bodySmall
                            .copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary),
                  onPressed: _pickResume,
                  tooltip: 'Change & Analyze Resume',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_isAnalyzingResume) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analyzing Resume with AI...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Extracting skills, projects, hackathons & certifications profile...',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (hasParsedData) ...[
            // 🛠️ Skills Card
            if (_parsedResumeSkills.isNotEmpty) ...[
              GlassCard(
                padding: const EdgeInsets.all(14),
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.code_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'EXTRACTED SKILLS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF10B981), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _parsedResumeSkills.map((skill) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 🚀 Projects Card
            if (_parsedResumeProjects.isNotEmpty) ...[
              GlassCard(
                padding: const EdgeInsets.all(14),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'PROJECTS DISCOVERED',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.primary, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _parsedResumeProjects.map((proj) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                proj,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 🏆 Hackathons Card
            if (_parsedResumeHackathons.isNotEmpty) ...[
              GlassCard(
                padding: const EdgeInsets.all(14),
                backgroundColor: AppColors.credGold.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.credGold.withValues(alpha: 0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, color: AppColors.credGold, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'HACKATHONS & COMPETITIONS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.credGold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _parsedResumeHackathons.map((hack) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.credGold, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                hack,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 📜 Certifications Card
            if (_parsedResumeCertifications.isNotEmpty) ...[
              GlassCard(
                padding: const EdgeInsets.all(14),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.secondary, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'CERTIFICATIONS & CREDENTIALS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.secondary, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _parsedResumeCertifications.map((cert) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: AppColors.secondary, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                cert,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],

          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.secondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your questions are personalized based on your analyzed resume & skill breakdown.',
                    style: AppTypography.bodySmall
                        .copyWith(color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        setState(() {
          _resumeFileName = result.files.first.name;
          _isAnalyzingResume = true;
        });

        if (path != null) {
          // Upload to Supabase Storage 'resumes' bucket & update user profile
          final cloudResumeUrl = await ref.read(userProfileProvider.notifier).setResumeFile(path, result.files.first.name);

          final api = ref.read(aiInterviewServiceProvider);
          final candidateName = ref.read(authProvider).fullName.trim();
          final resData = await api.parseResume(path, candidateName.isNotEmpty ? candidateName : 'Candidate');
          if (mounted && resData != null) {
            setState(() {
              _isAnalyzingResume = false;
              _parsedResumeSkills = resData.skills;
              _parsedResumeProjects = resData.projects;
              _parsedResumeHackathons = resData.hackathons;
              _parsedResumeCertifications = resData.certifications;
            });
            // Merge parsed resume skills with JD skills in provider
            final currentSetup = ref.read(interviewSetupProvider);
            final mergedSkills = {
              ...currentSetup.skills,
              ...resData.skills,
            }.toList();
            ref.read(interviewSetupProvider.notifier).updateConfig(
              resumePath: cloudResumeUrl ?? _resumeFileName,
              skills: mergedSkills,
            );
          } else {
            if (mounted) setState(() => _isAnalyzingResume = false);
          }
        } else {
          if (mounted) setState(() => _isAnalyzingResume = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isAnalyzingResume = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // STEP 5 — Summary & Launch
  // ─────────────────────────────────────────────────────────
  Widget _buildStep5Summary(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final authName = ref.watch(authProvider).fullName;
                  final displayName = authName.trim().isNotEmpty ? authName.split(' ').first : 'Candidate';
                  return Text('Ready, $displayName?',
                      style: AppTypography.headlineMobile
                          .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface));
                }),
                const SizedBox(height: 4),
                Text('Review your session configuration',
                    style: AppTypography.bodyMedium
                        .copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSummaryRow('TARGET ROLE', _roleLabel,
              Icons.work_rounded, AppColors.primary, cs),
          const SizedBox(height: 8),
          _buildSummaryRow('INTERVIEW MODE', _selectedModeTitle,
              Icons.tune_rounded, const Color(0xFF0284C7), cs),
          const SizedBox(height: 8),
          _buildSummaryRow('EVALUATION MATRIX', 'Technical 35% · Edge 25% · Keywords 20% · Comm 20%',
              Icons.analytics_rounded, const Color(0xFF10B981), cs),
          const SizedBox(height: 8),
          _buildSummaryRow('INTERVIEW TYPE', _typeLabel,
              Icons.psychology_rounded, AppColors.secondary, cs),
          const SizedBox(height: 8),
          _buildSummaryRow('DIFFICULTY', _difficultyLabel,
              Icons.bar_chart_rounded, AppColors.tertiary, cs),
          const SizedBox(height: 8),
          _buildSummaryRow('DURATION', '$_durationMinutesLabel min · $_durationNameLabel',
              Icons.timer_rounded, cs.onSurface, cs),
          const SizedBox(height: 8),
          _buildSummaryRow('RESUME', _resumeFileName ?? 'No resume uploaded',
              Icons.picture_as_pdf_rounded, AppColors.error, cs),
          const SizedBox(height: 8),
          const SizedBox(height: 20),

          GradientButton(
            text: 'Start AI Interview',
            icon: Icons.bolt_rounded,
            onPressed: () async {
              // ✅ FIX 6: Final write — fills any gaps from skipped steps
              final authState = ref.read(authProvider);
              final realName = authState.fullName.trim().isNotEmpty
                  ? authState.fullName.trim()
                  : 'Candidate';
              final selectedBlock = ref.read(interviewBlocksProvider).selectedBlock;
              final currentSetup = ref.read(interviewSetupProvider);

              // Merge parsed resume skills with JD skills (deduped)
              final mergedSkills = {
                ...currentSetup.skills,
                ..._parsedResumeSkills,
                ...(selectedBlock?.requiredSkills ?? []),
              }.toList();

              ref.read(interviewSetupProvider.notifier).updateConfig(
                candidateName: realName,
                jobRole: currentSetup.jobRole.isNotEmpty
                    ? currentSetup.jobRole
                    : (selectedBlock?.title ?? _roleLabel),
                jobDescriptionText: currentSetup.jobDescriptionText ?? selectedBlock?.description,
                experienceLevel: currentSetup.experienceLevel.isNotEmpty
                    ? currentSetup.experienceLevel
                    : (selectedBlock?.experienceLevel ?? _experienceLevel),
                difficulty: currentSetup.difficulty.isNotEmpty
                    ? currentSetup.difficulty
                    : (selectedBlock?.difficulty ?? _difficultyLabel),
                interviewType: currentSetup.interviewType.isNotEmpty
                    ? currentSetup.interviewType
                    : (selectedBlock?.interviewType ?? _typeLabel),
                targetQuestionCount: currentSetup.targetQuestionCount > 0
                    ? currentSetup.targetQuestionCount
                    : (selectedBlock?.targetQuestionCount ?? _targetQuestionCount),
                modeId: _selectedModeId,
                modeDisplayName: _selectedModeTitle,
                voicePersona: _selectedVoicePersona,
                speechRate: _selectedSpeechRate,
                resumePath: _resumeFileName,
                skills: mergedSkills,
                enrolledCourses: const [],
              );

              final success =
                  await ref.read(subscriptionProvider.notifier).consumeTrial();
              if (!mounted) return;
              if (success) {
                context.push('/interview/session');
              } else {
                CDAPaywallSheet.show(context);
              }
            },
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _goToStep(0),
              child: Text('Edit Configuration',
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, IconData icon, Color color, ColorScheme cs) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.codeMono.copyWith(
                        fontSize: 8,
                        letterSpacing: 1,
                        color: cs.outline,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTypography.titleMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }



}

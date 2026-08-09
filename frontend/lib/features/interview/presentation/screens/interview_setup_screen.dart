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
import '../../data/interview_setup_provider.dart';
import '../../data/ai_interview_service.dart';

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

const _profileName = 'Arjun Vardhan';
const _profileResume = 'Arjun_Vardhan_Resume.pdf';

class InterviewSetupScreen extends ConsumerStatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  ConsumerState<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends ConsumerState<InterviewSetupScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  InterviewRole? _selectedRole = InterviewRole.fullstack;
  String _customRoleText = '';
  final TextEditingController _customRoleCtrl = TextEditingController();

  InterviewType? _selectedType = InterviewType.technical;
  double _difficulty = 2; // 1-Beginner, 2-Intermediate, 3-Advanced
  InterviewDuration _selectedDuration = InterviewDuration.standard;
  String? _resumeFileName = _profileResume;

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
    _pageController = PageController();
    _progressAnim = AnimationController(
        vsync: this, duration: AppConstants.animationNormal);
    _progressValue =
        Tween<double>(begin: 1 / _totalSteps, end: 1 / _totalSteps).animate(
            CurvedAnimation(
                parent: _progressAnim, curve: Curves.easeOutCubic));
    _progressAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        return _customRoleText.isNotEmpty ? _customRoleText : 'Custom Job Role';
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

  String get _durationQRange {
    switch (_selectedDuration) {
      case InterviewDuration.short:
        return '3–5 questions';
      case InterviewDuration.detailed:
        return '8–12 questions';
      default:
        return '5–8 questions';
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
  // STEP 1 — Role Selection (10 Predefined Backend Roles)
  // ─────────────────────────────────────────────────────────
  Widget _buildStep1Role(ColorScheme cs) {
    final roles = [
      (InterviewRole.java, Icons.coffee_rounded, 'Java Developer'),
      (InterviewRole.fullstack, Icons.layers_rounded, 'Full Stack'),
      (InterviewRole.frontend, Icons.code_rounded, 'Frontend'),
      (InterviewRole.backend, Icons.terminal_rounded, 'Backend'),
      (InterviewRole.python, Icons.data_object_rounded, 'Python Developer'),
      (InterviewRole.aiMl, Icons.psychology_rounded, 'AI/ML Engineer'),
      (InterviewRole.dataScience, Icons.analytics_rounded, 'Data Scientist'),
      (InterviewRole.dataAnalyst, Icons.insert_chart_rounded, 'Data Analyst'),
      (InterviewRole.devops, Icons.cloud_done_rounded, 'DevOps Engineer'),
      (InterviewRole.customRole, Icons.edit_note_rounded, 'Custom Role'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What role are you targeting?',
              style: AppTypography.headlineMobile
                  .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text('Choose from all 10 official engineering roles',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: roles
                .map((r) => _buildRoleCard(r.$1, r.$2, r.$3, cs))
                .toList(),
          ),
          if (_selectedRole == InterviewRole.customRole) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customRoleCtrl,
              decoration: InputDecoration(
                labelText: 'Enter Custom Job Role',
                hintText: 'e.g. Senior iOS Architect',
                prefixIcon: const Icon(Icons.work_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (val) => setState(() => _customRoleText = val),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleCard(InterviewRole role, IconData icon, String label, ColorScheme cs) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => _selectAndAdvance(() => setState(() => _selectedRole = role)),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.09)
              : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.primary : cs.outlineVariant,
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 10)
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 26,
                color: isSelected
                    ? AppColors.primary
                    : cs.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppColors.primary
                      : cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
      onTap: () =>
          _selectAndAdvance(() => setState(() => _selectedType = type)),
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
  // STEP 3 — Difficulty & Session Duration
  // ─────────────────────────────────────────────────────────
  Widget _buildStep3DiffDuration(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          const SizedBox(height: 24),

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
                    'Session configured for $_durationMinutesLabel mins ($_durationQRange) at $_difficultyLabel level.',
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
      onTap: () => setState(() => _difficulty = level.toDouble()),
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
      onTap: () => setState(() => _selectedDuration = duration),
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
  Widget _buildStep4Resume(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your resume',
              style: AppTypography.headlineMobile
                  .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text(
            'We\'ve loaded your resume from your profile. You can replace it if needed.',
            style: AppTypography.bodyMedium
                .copyWith(color: cs.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 24),

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
                        _resumeFileName ?? _profileResume,
                        style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold, color: cs.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PDF Document · Loaded from profile',
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
                  tooltip: 'Change resume',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.secondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The AI will personalise questions based on your experience and listed skills.',
                    style: AppTypography.bodySmall
                        .copyWith(color: cs.onSurfaceVariant, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _resumeFileName = result.files.first.name);
      }
    } catch (_) {}
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
                Text('Ready, $_profileName?',
                    style: AppTypography.headlineMobile
                        .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
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
          _buildSummaryRow('INTERVIEW TYPE', _typeLabel,
              Icons.psychology_rounded, AppColors.secondary, cs),
          const SizedBox(height: 8),
          _buildSummaryRow('DIFFICULTY', _difficultyLabel,
              Icons.bar_chart_rounded, AppColors.tertiary, cs),
          const SizedBox(height: 8),
          _buildSummaryRow('DURATION', '$_durationMinutesLabel min · $_durationNameLabel',
              Icons.timer_rounded, cs.onSurface, cs),
          const SizedBox(height: 8),
          _buildSummaryRow('RESUME', _resumeFileName ?? _profileResume,
              Icons.picture_as_pdf_rounded, AppColors.error, cs),

          const SizedBox(height: 20),

          GradientButton(
            text: 'Start AI Interview',
            icon: Icons.bolt_rounded,
            onPressed: () {
              ref.read(interviewSetupProvider.notifier).updateConfig(
                    candidateName: 'Arjun Verma',
                    jobRole: _roleLabel,
                    difficulty: _difficultyLabel,
                    interviewType: _typeLabel,
                    targetQuestionCount: _targetQuestionCount,
                    resumePath: _resumeFileName ?? _profileResume,
                    enrolledCourses: const ['Full-Stack Web Development', 'System Design & Microservices'],
                    skills: const ['Java', 'Flutter', 'Python', 'Dart', 'FastAPI'],
                  );
              final success =
                  ref.read(subscriptionProvider.notifier).consumeTrial();
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

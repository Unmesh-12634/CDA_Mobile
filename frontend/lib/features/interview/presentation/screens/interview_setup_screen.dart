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

// ─────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────
enum InterviewRole { frontend, backend, fullstack, mobile, devops, dataScience }
enum InterviewType { technical, behavioral, systemDesign }
enum InterviewDuration { ten, twentyFive, fortyFive }

// ─────────────────────────────────────────────────
// Mock Profile Data (will be replaced by real provider)
// ─────────────────────────────────────────────────
const _profileName = 'Arjun Vardhan';
const _profileResume = 'Arjun_Vardhan_Resume.pdf'; // pre-loaded from profile

// ─────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────
class InterviewSetupScreen extends ConsumerStatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  ConsumerState<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends ConsumerState<InterviewSetupScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────
  int _currentStep = 0;
  InterviewRole? _selectedRole;
  InterviewType? _selectedType;
  double _difficulty = 2; // 1-3
  InterviewDuration _selectedDuration = InterviewDuration.twentyFive;
  // Pre-filled from profile — user can change on step 4
  String? _resumeFileName = _profileResume;

  late final PageController _pageController;
  late final AnimationController _progressAnim;
  late Animation<double> _progressValue;

  // Steps: Role → Type → Difficulty → Duration → Resume → Summary
  static const int _totalSteps = 5; // reduced: name removed, merged

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnim.dispose();
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

  /// Auto-advances after a brief moment so user sees the selection flash
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

  // ── Computed Labels ─────────────────────────────
  String get _difficultyLabel {
    if (_difficulty <= 1.4) return 'Beginner';
    if (_difficulty <= 2.4) return 'Intermediate';
    return 'Advanced';
  }

  String get _difficultyDesc {
    if (_difficulty <= 1.4) {
      return 'Core concepts and fundamental problem-solving. Great for entry-level roles.';
    }
    if (_difficulty <= 2.4) {
      return 'Practical implementation, architectural patterns, and real-world optimizations.';
    }
    return 'Deep specialised knowledge, complex system scaling, and senior engineering edge-cases.';
  }

  Color get _difficultyColor {
    if (_difficulty <= 1.4) return const Color(0xFF2E7D32);
    if (_difficulty <= 2.4) return AppColors.primary;
    return const Color(0xFFB75E00);
  }

  IconData get _difficultyIcon {
    if (_difficulty <= 1.4) return Icons.school_rounded;
    if (_difficulty <= 2.4) return Icons.workspace_premium_rounded;
    return Icons.military_tech_rounded;
  }

  String get _durationQRange {
    switch (_selectedDuration) {
      case InterviewDuration.ten: return '2–3 questions';
      case InterviewDuration.twentyFive: return '5–7 questions';
      case InterviewDuration.fortyFive: return '10–12 questions';
    }
  }


  String get _durationLabel {
    switch (_selectedDuration) {
      case InterviewDuration.ten:
        return '10';
      case InterviewDuration.twentyFive:
        return '25';
      case InterviewDuration.fortyFive:
        return '45';
    }
  }

  String get _durationSub {
    switch (_selectedDuration) {
      case InterviewDuration.ten:
        return 'Blitz';
      case InterviewDuration.twentyFive:
        return 'Standard';
      case InterviewDuration.fortyFive:
        return 'Deep Dive';
    }
  }

  String get _roleLabel {
    switch (_selectedRole) {
      case InterviewRole.frontend:
        return 'Frontend';
      case InterviewRole.backend:
        return 'Backend';
      case InterviewRole.fullstack:
        return 'Fullstack';
      case InterviewRole.mobile:
        return 'Mobile';
      case InterviewRole.devops:
        return 'DevOps';
      case InterviewRole.dataScience:
        return 'Data Science';
      case null:
        return '—';
    }
  }

  String get _typeLabel {
    switch (_selectedType) {
      case InterviewType.technical:
        return 'Technical Screening';
      case InterviewType.behavioral:
        return 'Behavioral (HR)';
      case InterviewType.systemDesign:
        return 'System Design';
      case null:
        return '—';
    }
  }

  // ── Build ───────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _buildAppBar(context, cs),
      body: Column(
        children: [
          _buildProgressHeader(cs),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepWrapper(_buildStep1Role(cs)),
                _buildStepWrapper(_buildStep2Type(cs)),
                _buildStepWrapper(_buildStep3DiffDuration(cs)),
                _buildStepWrapper(_buildStep4Resume(cs)),
                _buildStep5Summary(cs), // summary has its own scroll
              ],
            ),
          ),
          _buildNavControls(cs),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme cs) {
    return AppBar(
      backgroundColor: cs.surface.withValues(alpha: 0.9),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
        onPressed: () =>
            _currentStep == 0 ? context.pop() : _prevStep(),
      ),
      title: Text(
        'Interview Setup',
        style: AppTypography.titleMedium
            .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  _profileName.split(' ').first, // first name only
                  style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.marginMobile, 10, AppConstants.marginMobile, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: AppTypography.codeMono.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              Text(
                _stepNames[_currentStep],
                style: AppTypography.bodyMedium.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: AnimatedBuilder(
              animation: _progressValue,
              builder: (_, __) => LinearProgressIndicator(
                value: _progressValue.value,
                backgroundColor: cs.surfaceContainerHigh,
                color: AppColors.primary,
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepWrapper(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.marginMobile, 24, AppConstants.marginMobile, 24),
      child: child,
    );
  }

  Widget _buildNavControls(ColorScheme cs) {
    final isLast = _currentStep == _totalSteps - 1;
    final isTapAdvanceStep = [0, 1].contains(_currentStep);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppConstants.marginMobile, 12, AppConstants.marginMobile, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4))
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 22),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: _prevStep,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 14),
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
                        ? '✨  Tap a role to continue'
                        : '✨  Tap a type to continue',
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
  // STEP 1 — Role Selection (TAP → AUTO ADVANCE)
  // ─────────────────────────────────────────────────────────
  Widget _buildStep1Role(ColorScheme cs) {
    final roles = [
      (InterviewRole.frontend, Icons.code_rounded, 'Frontend'),
      (InterviewRole.backend, Icons.terminal_rounded, 'Backend'),
      (InterviewRole.fullstack, Icons.layers_rounded, 'Fullstack'),
      (InterviewRole.mobile, Icons.smartphone_rounded, 'Mobile'),
      (InterviewRole.devops, Icons.cloud_done_rounded, 'DevOps'),
      (InterviewRole.dataScience, Icons.storage_rounded, 'Data Science'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What role are you targeting?',
            style: AppTypography.headlineMobile
                .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text('Tap to select and continue instantly',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: roles
              .map((r) => _buildRoleCard(r.$1, r.$2, r.$3, cs))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRoleCard(InterviewRole role, IconData icon, String label, ColorScheme cs) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => _selectAndAdvance(() => setState(() => _selectedRole = role)),
      child: AnimatedScale(
        scale: isSelected ? 0.95 : 1.0,
        duration: AppConstants.animationFast,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.09)
                : cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(
                color: isSelected ? AppColors.primary : cs.outlineVariant,
                width: isSelected ? 2 : 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 14)
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 34,
                  color: isSelected
                      ? AppColors.primary
                      : cs.onSurfaceVariant),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.primary
                        : cs.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STEP 2 — Interview Type (TAP → AUTO ADVANCE)
  // ─────────────────────────────────────────────────────────
  Widget _buildStep2Type(ColorScheme cs) {
    final types = [
      (InterviewType.technical, Icons.psychology_rounded,
          'Technical Screening',
          'Algorithm, architecture, and coding proficiency.',
          AppColors.secondary),
      (InterviewType.behavioral, Icons.groups_rounded, 'Behavioral (HR)',
          'Culture fit, soft skills, and career background.', AppColors.tertiary),
      (InterviewType.systemDesign, Icons.schema_rounded, 'System Design',
          'Scalability, infrastructure, and high-level logic.',
          AppColors.primary),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select interview type',
            style: AppTypography.headlineMobile
                .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text('Tap to select and continue instantly',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        ...types.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTypeCard(t.$1, t.$2, t.$3, t.$4, t.$5, cs),
            )),
      ],
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.07) : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
              color: isSelected ? color : cs.outlineVariant,
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.1), blurRadius: 12)
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: AppConstants.animationFast,
              child: Icon(Icons.check_circle_rounded, color: color, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // STEP 3 — Difficulty + Duration (premium redesign)
  // ─────────────────────────────────────────────────────────
  Widget _buildStep3DiffDuration(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── SECTION 1: Challenge Level ───────────────────
        _buildSectionChip(Icons.bar_chart_rounded, 'CHALLENGE LEVEL', AppColors.primary),
        const SizedBox(height: 14),

        // Difficulty cards (3 visual cards instead of slider)
        Row(
          children: [
            Expanded(child: _buildDiffCard(1, 'Beginner', Icons.school_rounded,
                'Entry level concepts', const Color(0xFF2E7D32), cs)),
            const SizedBox(width: 10),
            Expanded(child: _buildDiffCard(2, 'Intermediate', Icons.workspace_premium_rounded,
                'Real-world patterns', AppColors.primary, cs)),
            const SizedBox(width: 10),
            Expanded(child: _buildDiffCard(3, 'Advanced', Icons.military_tech_rounded,
                'Senior expertise', const Color(0xFFB75E00), cs)),
          ],
        ),

        const SizedBox(height: 8),

        // Live description chip
        AnimatedSwitcher(
          duration: AppConstants.animationFast,
          child: Container(
            key: ValueKey(_difficultyLabel),
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
                        color: cs.onSurfaceVariant, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── SECTION 2: Session Duration ───────────────────
        _buildSectionChip(Icons.timer_rounded, 'SESSION DURATION', AppColors.secondary),
        const SizedBox(height: 14),

        // Duration cards
        Row(
          children: [
            Expanded(
                child: _buildDurationCard(
                    InterviewDuration.ten, '10', 'Blitz', '2–3 questions', Icons.flash_on_rounded, cs)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildDurationCard(
                    InterviewDuration.twentyFive, '25', 'Standard', '5–7 questions', Icons.schedule_rounded, cs)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildDurationCard(
                    InterviewDuration.fortyFive, '45', 'Deep Dive', '10–12 questions', Icons.psychology_rounded, cs)),
          ],
        ),

        const SizedBox(height: 16),

        // Info banner
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
                  'You\'ll get $_durationQRange tailored to your '  
                  '$_roleLabel role at $_difficultyLabel level.',
                  style: AppTypography.bodySmall.copyWith(
                      color: cs.onSurfaceVariant, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? color : cs.outlineVariant,
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12)]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.15 : 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? color : cs.outline, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isSelected ? color : cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppTypography.codeMono.copyWith(
                  fontSize: 8,
                  color: cs.outline,
                  letterSpacing: 0.3),
              textAlign: TextAlign.center,
              maxLines: 2,
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
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.primary : cs.outlineVariant,
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10)]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : cs.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? AppColors.primary : cs.outline,
                  size: 20),
            ),
            const SizedBox(height: 8),
            Text(minutes,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppColors.primary
                        : cs.onSurface)),
            Text('MIN',
                style: AppTypography.codeMono.copyWith(
                    fontSize: 8,
                    letterSpacing: 1,
                    color: isSelected ? AppColors.primary : cs.outline,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(label,
                style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : cs.onSurface,
                    fontSize: 11)),
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
  // STEP 4 — Resume (pre-filled from profile)
  // ─────────────────────────────────────────────────────────
  Widget _buildStep4Resume(ColorScheme cs) {
    return Column(
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

        // Pre-filled resume card
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
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Loaded from your profile',
                            style: AppTypography.bodySmall.copyWith(
                                color: Colors.green.shade700, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _pickResume,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6)),
                child: const Text('Change',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Upload different resume option
        GestureDetector(
          onTap: _pickResume,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(
                  color: cs.outline.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                  width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file_rounded,
                    color: cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                Text('Upload a different resume',
                    style: AppTypography.bodyMedium.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.secondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The AI will personalise questions based on your experience and listed skills.',
                  style: AppTypography.bodySmall
                      .copyWith(color: cs.onSurfaceVariant, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _resumeFileName = result.files.first.name);
      }
    } catch (_) {
      // Silently ignore
    }
  }

  // ─────────────────────────────────────────────────────────
  // STEP 5 — Summary & Launch
  // ─────────────────────────────────────────────────────────
  Widget _buildStep5Summary(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.marginMobile, 24, AppConstants.marginMobile, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 14),
                Text('Ready, $_profileName?',
                    style: AppTypography.headlineMobile
                        .copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text('Review your session config',
                    style: AppTypography.bodyMedium
                        .copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Config cards
          _buildSummaryRow('TARGET ROLE', _roleLabel,
              Icons.work_rounded, AppColors.primary, cs),
          const SizedBox(height: 10),
          _buildSummaryRow('INTERVIEW TYPE', _typeLabel,
              Icons.psychology_rounded, AppColors.secondary, cs),
          const SizedBox(height: 10),
          _buildSummaryRow('DIFFICULTY', _difficultyLabel,
              Icons.bar_chart_rounded, AppColors.tertiary, cs),
          const SizedBox(height: 10),
          _buildSummaryRow('DURATION', '$_durationLabel min · $_durationSub',
              Icons.timer_rounded, cs.onSurface, cs),
          const SizedBox(height: 10),
          _buildSummaryRow('RESUME', _resumeFileName ?? _profileResume,
              Icons.picture_as_pdf_rounded, AppColors.error, cs),

          const SizedBox(height: 20),

          // AI note
          GlassCard(
            backgroundColor: AppColors.primary.withValues(alpha: 0.04),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15)),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI model calibrated for $_roleLabel · $_difficultyLabel level.',
                    style: AppTypography.bodySmall.copyWith(
                        color: cs.onSurfaceVariant, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          GradientButton(
            text: 'Start AI Interview',
            icon: Icons.bolt_rounded,
            onPressed: () {
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, IconData icon, Color color, ColorScheme cs) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
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
                        fontSize: 14,
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

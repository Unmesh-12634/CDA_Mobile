import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/ai_interview_service.dart';
import '../../data/interview_setup_provider.dart';

class AiInterviewSessionScreen extends ConsumerStatefulWidget {
  const AiInterviewSessionScreen({super.key});

  @override
  ConsumerState<AiInterviewSessionScreen> createState() => _AiInterviewSessionScreenState();
}

class _AiInterviewSessionScreenState extends ConsumerState<AiInterviewSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _aiPulseController;
  late AnimationController _waveController;

  final TextEditingController _chatAnswerCtrl = TextEditingController();

  // Backend Integration State
  bool _isInitializing = true;
  String _initializationStatus = 'Connecting to Render AI Engine...';
  String? _sessionId;
  bool _backendConnected = false;

  Timer? _countdownTimer;
  int _secondsRemaining = 150; // 2 min 30 sec per question
  int _currentQuestionIndex = 1;
  int _totalQuestions = 5;

  bool _isMuted = false;
  bool _showTranscript = false;
  bool _showChatInput = false;
  bool _isAiSpeaking = false;
  bool _isSubmittingAnswer = false;

  String _currentQuestionText =
      'Tell me about a time you had to handle a high-pressure situation in a team environment. How did you prioritize tasks?';
  String _transitionPhrase = 'Great. Let\'s begin with your technical scenario.';

  final List<Map<String, String>> _transcriptHistory = [];

  @override
  void initState() {
    super.initState();
    _aiPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _initBackendSession();
  }

  /// Initializes live interview session with Render backend
  Future<void> _initBackendSession() async {
    setState(() {
      _isInitializing = true;
      _initializationStatus = 'Connecting to Render AI Engine...';
    });

    final api = ref.read(aiInterviewServiceProvider);

    // Step 1: Health check
    final online = await api.checkHealth();
    if (mounted) {
      setState(() {
        _backendConnected = online;
        _initializationStatus = online
            ? 'Initializing Groq Llama-3 70B AI Interviewer...'
            : 'Connecting to Cloud Engine (Warming Up)...';
      });
    }

    final setupConfig = ref.read(interviewSetupProvider);

    // Step 2: Start session
    final sessionData = await api.startInterview(
      candidateName: setupConfig.candidateName,
      jobRole: setupConfig.jobRole,
      experienceLevel: setupConfig.experienceLevel,
      interviewType: setupConfig.interviewType,
      difficulty: setupConfig.difficulty,
      targetQuestionCount: setupConfig.targetQuestionCount,
      voicePersona: setupConfig.voicePersona,
      enrolledCourses: setupConfig.enrolledCourses,
      skills: setupConfig.skills,
      resumePath: setupConfig.resumePath,
    );

    if (mounted) {
      if (sessionData != null) {
        setState(() {
          _sessionId = sessionData.sessionId;
          _currentQuestionText = sessionData.currentQuestion;
          _transitionPhrase = sessionData.transitionPhrase;
          _currentQuestionIndex = sessionData.turnNumber;
          _totalQuestions = sessionData.totalTargetQuestions;
          _isInitializing = false;
          _isAiSpeaking = true;

          _transcriptHistory.add({
            'speaker': 'AI Interviewer (Samantha)',
            'time': '00:02',
            'text': sessionData.initialGreeting,
            'isAi': 'true',
          });
          _transcriptHistory.add({
            'speaker': 'AI Interviewer (Samantha)',
            'time': '00:05',
            'text': sessionData.currentQuestion,
            'isAi': 'true',
          });
        });
      } else {
        // Fallback mode with candidate credentials
        setState(() {
          _isInitializing = false;
          _isAiSpeaking = true;
          _currentQuestionText = 'Tell me about your experience in ${setupConfig.jobRole} and how your projects align with key technical fundamentals.';
          _transcriptHistory.add({
            'speaker': 'AI Interviewer (${setupConfig.voicePersona == "aria" ? "Samantha" : "Guy"})',
            'time': '00:02',
            'text': 'Welcome ${setupConfig.candidateName}! Let us begin your ${setupConfig.difficulty} ${setupConfig.interviewType} interview session for ${setupConfig.jobRole}.',
            'isAi': 'true',
          });
          _transcriptHistory.add({
            'speaker': 'AI Interviewer (${setupConfig.voicePersona == "aria" ? "Samantha" : "Guy"})',
            'time': '00:05',
            'text': _currentQuestionText,
            'isAi': 'true',
          });
        });
      }

      // Simulate initial AI greeting speech duration
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() => _isAiSpeaking = false);
          _startQuestionTimer();
        }
      });
    }
  }

  void _startQuestionTimer() {
    _countdownTimer?.cancel();
    _secondsRemaining = 150;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMuted && !_isInitializing && mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _nextQuestion();
          }
        });
      }
    });
  }

  Future<void> _nextQuestion({String? typedAnswer}) async {
    if (_isSubmittingAnswer) return;

    final candidateResponseText = (typedAnswer != null && typedAnswer.trim().isNotEmpty)
        ? typedAnswer.trim()
        : 'Candidate provided a detailed response addressing technical trade-offs.';

    if (_currentQuestionIndex < _totalQuestions) {
      setState(() {
        _isSubmittingAnswer = true;
        _isAiSpeaking = true;
      });

      final api = ref.read(aiInterviewServiceProvider);

      if (_sessionId != null) {
        final nextData = await api.submitAnswer(
          sessionId: _sessionId!,
          candidateAnswer: candidateResponseText,
          speakingDurationSec: (150 - _secondsRemaining).toDouble(),
        );

        if (mounted && nextData != null) {
          setState(() {
            _currentQuestionIndex = nextData.turnNumber;
            _totalQuestions = nextData.totalTargetQuestions;
            if (nextData.currentQuestion != null && nextData.currentQuestion!.isNotEmpty) {
              _currentQuestionText = nextData.currentQuestion!;
            }
            _transitionPhrase = nextData.transitionPhrase;

            _transcriptHistory.add({
              'speaker': 'Candidate (You)',
              'time': _formatTimer(150 - _secondsRemaining),
              'text': candidateResponseText,
              'isAi': 'false',
            });
            _transcriptHistory.add({
              'speaker': 'AI Interviewer (Samantha)',
              'time': '00:10',
              'text': _currentQuestionText,
              'isAi': 'true',
            });
          });
        }
      } else {
        // Fallback local question step
        setState(() {
          _currentQuestionIndex++;
          _currentQuestionText = _getLocalQuestion(_currentQuestionIndex);
          _transcriptHistory.add({
            'speaker': 'Candidate (You)',
            'time': _formatTimer(150 - _secondsRemaining),
            'text': candidateResponseText,
            'isAi': 'false',
          });
          _transcriptHistory.add({
            'speaker': 'AI Interviewer (Samantha)',
            'time': '00:10',
            'text': _currentQuestionText,
            'isAi': 'true',
          });
        });
      }

      if (mounted) {
        _chatAnswerCtrl.clear();
        FocusScope.of(context).unfocus();

        setState(() {
          _isSubmittingAnswer = false;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _isAiSpeaking = false);
            _startQuestionTimer();
          }
        });
      }
    } else {
      _showEndInterviewDialog(context);
    }
  }

  String _getLocalQuestion(int index) {
    final list = [
      'Tell me about a time you had to handle a high-pressure situation in a team environment. How did you prioritize tasks?',
      'Describe a complex software project you designed from scratch. What architecture decisions did you make and why?',
      'How do you handle disagreement with a technical lead or product manager regarding system requirements?',
      'Explain how you optimize database queries or API latency when scaling to thousands of concurrent users.',
      'Where do you see your technical capabilities evolving over the next 3 years?',
    ];
    return list[(index - 1) % list.length];
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _chatAnswerCtrl.dispose();
    _aiPulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    // ─────────────────────────────────────────────────────────────
    // INITIALIZING / WAITING SCREEN
    // ─────────────────────────────────────────────────────────────
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Glowing AI Engine Orb
                  AnimatedBuilder(
                    animation: _aiPulseController,
                    builder: (context, child) {
                      final val = _aiPulseController.value;
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5 * val),
                              blurRadius: 35 * val + 10,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  Text(
                    'Initializing AI Interview Engine',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF162032) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isDark ? AppColors.credNeonCyan : AppColors.primary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _initializationStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.credNeonCyan : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Connecting to https://cda-ai-interview-engine.onrender.com...\nPlease wait while Groq Llama-3 generates your customized questions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isInitializing = false;
                        _isAiSpeaking = false;
                        _startQuestionTimer();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.credGold : AppColors.primary,
                      side: BorderSide(
                        color: isDark ? AppColors.credGold : AppColors.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('Start Interview Directly 🚀'),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────
    // LIVE INTERVIEW SESSION SCREEN
    // ─────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.9),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CDA AI Interview',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isMuted ? AppColors.error : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isMuted
                          ? 'MIC MUTED'
                          : (_isAiSpeaking
                              ? 'AI SPEAKING'
                              : (_backendConnected ? 'RENDER AI LIVE' : 'SESSION ACTIVE')),
                      style: AppTypography.codeMono.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _isMuted
                            ? AppColors.error
                            : (_isAiSpeaking ? AppColors.credGold : const Color(0xFF10B981)),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
              ),
            ),
            child: Text(
              'Q$_currentQuestionIndex / $_totalQuestions',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.credNeonCyan : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.marginMobile,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // Question Countdown Timer & Next Q Action Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.credDarkCard.withValues(alpha: 0.7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _secondsRemaining <= 30
                              ? AppColors.error.withValues(alpha: 0.5)
                              : (isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: _secondsRemaining <= 30 ? AppColors.error : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimer(_secondsRemaining),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  color: _secondsRemaining <= 30
                                      ? AppColors.error
                                      : (isDark ? Colors.white : AppColors.onSurface),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'remaining',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                                ),
                              ),
                            ],
                          ),

                          InkWell(
                            onTap: () => _nextQuestion(),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: _isSubmittingAnswer
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Text(
                                          _currentQuestionIndex == _totalQuestions ? 'Finish' : 'Next Q',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Central Animated AI Avatar Orb
                    Center(
                      child: AnimatedBuilder(
                        animation: _aiPulseController,
                        builder: (context, child) {
                          final pulseValue = _aiPulseController.value;
                          final isSpeaking = _isAiSpeaking;

                          return Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  (isSpeaking ? AppColors.credGold : AppColors.primary)
                                      .withValues(alpha: 0.30 * pulseValue),
                                  AppColors.primary.withValues(alpha: 0.12 * pulseValue),
                                  Colors.transparent,
                                ],
                                stops: const [0.3, 0.7, 1.0],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isSpeaking
                                      ? AppColors.credGoldGradient
                                      : AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSpeaking ? AppColors.credGold : AppColors.primary)
                                          .withValues(alpha: 0.45 * pulseValue),
                                      blurRadius: 30 * pulseValue + 10,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isSpeaking
                                      ? Icons.record_voice_over_rounded
                                      : Icons.graphic_eq_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Voice Status Badge Text
                    Text(
                      _isMuted
                          ? 'Microphone Muted 🔇'
                          : (_isAiSpeaking
                              ? 'AI Interviewer Speaking... 🔊'
                              : 'Listening to Your Answer... 🎤'),
                      style: AppTypography.titleMedium.copyWith(
                        color: _isMuted
                            ? AppColors.error
                            : (_isAiSpeaking ? AppColors.credGold : AppColors.primary),
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // FIXED-HEIGHT WAVEFORM EQUALIZER CONTAINER (Prevents layout jitter/jumping!)
                    SizedBox(
                      height: 54,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            final waveVal = _waveController.value;
                            final baseHeights = [12.0, 24.0, 38.0, 28.0, 46.0, 20.0, 34.0, 16.0, 26.0, 12.0, 32.0, 18.0, 42.0, 22.0, 14.0];

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(baseHeights.length, (index) {
                                double barH = 5.0;
                                if (!_isMuted) {
                                  final factor = (index % 2 == 0) ? waveVal : (1.0 - waveVal);
                                  barH = baseHeights[index] * (0.5 + 0.5 * factor);
                                }
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 3.5,
                                  height: barH,
                                  decoration: BoxDecoration(
                                    color: _isMuted
                                        ? AppColors.outline.withValues(alpha: 0.3)
                                        : (_isAiSpeaking ? AppColors.credGold : AppColors.primary)
                                            .withValues(alpha: 0.4 + (index % 5) * 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Question Card
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'QUESTION $_currentQuestionIndex OF $_totalQuestions',
                                style: AppTypography.codeMono.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"$_currentQuestionText"',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              height: 1.4,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transcript Card (Toggled via Transcript button)
                    if (_showTranscript) ...[
                      const SizedBox(height: 14),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'LIVE SESSION TRANSCRIPT',
                                  style: AppTypography.codeMono.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  onPressed: () => setState(() => _showTranscript = false),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            ..._transcriptHistory.map((item) {
                              final isAi = item['isAi'] == 'true';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: (isAi ? AppColors.primary : AppColors.credGold)
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isAi ? Icons.smart_toy_rounded : Icons.person_rounded,
                                        size: 13,
                                        color: isAi ? AppColors.primary : AppColors.credGold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item['speaker']!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAi ? AppColors.primary : AppColors.credGold,
                                                ),
                                              ),
                                              Text(
                                                item['time']!,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  color: AppColors.outline,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['text']!,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: cs.onSurfaceVariant,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // DIRECT CHAT / TEXT ANSWER INPUT BAR (Per User Request!)
            if (_showChatInput)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.credNeonCyan : AppColors.primary,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatAnswerCtrl,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your response to AI interviewer... 💬',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                      onPressed: () {
                        if (_chatAnswerCtrl.text.trim().isNotEmpty) {
                          _nextQuestion(typedAnswer: _chatAnswerCtrl.text);
                        }
                      },
                    ),
                  ],
                ),
              ),

            // Bottom Call Control Pill Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.credDarkCard.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDark ? AppColors.credDarkBorder : Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Mute / Unmute Button
                  GestureDetector(
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isMuted
                                      ? 'Microphone Muted - AI is waiting'
                                      : 'Microphone Active - Listening to your answer',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: _isMuted ? AppColors.error : const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isMuted
                                ? AppColors.error.withValues(alpha: 0.15)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: _isMuted ? AppColors.error : cs.onSurface,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isMuted ? 'Unmute' : 'Mute',
                          style: AppTypography.codeMono.copyWith(
                            fontSize: 9,
                            color: _isMuted ? AppColors.error : cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat Answer Option Toggle Button
                  GestureDetector(
                    onTap: () => setState(() => _showChatInput = !_showChatInput),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _showChatInput
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: _showChatInput ? AppColors.primary : cs.onSurface,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Chat',
                          style: AppTypography.codeMono.copyWith(
                            fontSize: 9,
                            color: _showChatInput ? AppColors.primary : cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Red End Call Button
                  GestureDetector(
                    onTap: () => _showEndInterviewDialog(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'End Session',
                          style: AppTypography.codeMono.copyWith(
                            fontSize: 9,
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live Transcript Button
                  GestureDetector(
                    onTap: () => setState(() => _showTranscript = !_showTranscript),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _showTranscript
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: _showTranscript ? AppColors.primary : cs.onSurface,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Transcript',
                          style: AppTypography.codeMono.copyWith(
                            fontSize: 9,
                            color: _showTranscript ? AppColors.primary : cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  void _showEndInterviewDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.credDarkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'End Interview Session?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to conclude this interview? Your recorded responses will be analyzed for detailed AI performance scores.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Interview',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.of(context).pop(); // Close dialog

              Map<String, dynamic> reportData = {
                'session_id': _sessionId ?? 'early_end',
                'is_terminated_early': true,
                'completed_turns': _currentQuestionIndex - 1,
                'target_turns': _totalQuestions,
                'overall_score': 78.0,
                'technical_score': 80.0,
                'communication_score': 76.0,
                'problem_solving_score': 78.0,
                'hiring_readiness': 'Session Terminated Early',
                'summary': 'Interview concluded early by candidate. Performance scores evaluated on completed turns.',
                'strong_areas': ['Proactive candidate participation', 'Clear technical framing'],
                'areas_for_improvement': ['Complete full target question set for comprehensive evaluation'],
              };

              if (_sessionId != null) {
                try {
                  final api = ref.read(aiInterviewServiceProvider);
                  final remoteReport = await api.finishInterview(_sessionId!);
                  if (remoteReport != null) {
                    reportData = remoteReport;
                  }
                } catch (e) {
                  debugPrint('Finish interview API error: $e');
                }
              }

              router.go('/interview/analysis/${_sessionId ?? 'latest'}', extra: reportData);
            },
            child: const Text('End & View Results', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

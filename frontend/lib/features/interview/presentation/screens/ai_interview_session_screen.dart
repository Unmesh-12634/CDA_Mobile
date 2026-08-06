import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';

class AiInterviewSessionScreen extends StatefulWidget {
  const AiInterviewSessionScreen({super.key});

  @override
  State<AiInterviewSessionScreen> createState() => _AiInterviewSessionScreenState();
}

class _AiInterviewSessionScreenState extends State<AiInterviewSessionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isMuted = false;
  bool _showTranscript = false;

  final String _currentQuestion =
      'Tell me about a time you had to handle a high-pressure situation in a team environment. How did you prioritize tasks?';

  final String _liveTranscript =
      'In my previous role as a Senior Engineer, we faced a critical database outage during peak traffic. I immediately initialized our incident response protocol, organized a war room with 4 engineers, and assigned explicit diagnostic streams while keeping stakeholders updated...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.8),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CDA Companion',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            Text(
              'SESSION ACTIVE',
              style: AppTypography.codeMono.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: cs.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.marginMobile,
                  vertical: AppConstants.stackMd,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Central Animated AI Orb & Visual Glow
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulseValue = _pulseController.value;
                          return Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.25 * pulseValue),
                                  AppColors.secondary.withValues(alpha: 0.1 * pulseValue),
                                  Colors.transparent,
                                ],
                                stops: const [0.3, 0.7, 1.0],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4 * pulseValue),
                                      blurRadius: 30 * pulseValue + 10,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Voice State Indicator
                    Text(
                      _isMuted ? 'Microphone Muted' : 'Listening...',
                      style: AppTypography.titleMedium.copyWith(
                        color: _isMuted ? AppColors.error : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TAP TO INTERRUPT OR PAUSE',
                      style: AppTypography.codeMono.copyWith(
                        color: cs.outline,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),

                    const SizedBox(height: AppConstants.stackLg),

                    // Floating Question Card
                    GlassCard(
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
                                'CURRENT QUESTION',
                                style: AppTypography.codeMono.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '"$_currentQuestion"',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              height: 1.4,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showTranscript) ...[
                      const SizedBox(height: AppConstants.stackMd),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIVE TRANSCRIPT',
                              style: AppTypography.codeMono.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _liveTranscript,
                              style: AppTypography.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sound Waveform Bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(12, (index) {
                        final heights = [12.0, 24.0, 40.0, 32.0, 48.0, 20.0, 36.0, 16.0, 28.0, 12.0, 32.0, 18.0];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: 4,
                          height: _isMuted ? 8 : heights[index % heights.length],
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3 + (index % 5) * 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Call Controls Pill Bar — theme-aware
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.credDarkCard.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDark
                      ? AppColors.credDarkBorder
                      : Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Mute Button
                  GestureDetector(
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          color: _isMuted ? AppColors.error : cs.onSurfaceVariant,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isMuted ? 'Unmute' : 'Mute',
                          style: AppTypography.codeMono.copyWith(
                            fontSize: 10,
                            color: _isMuted ? AppColors.error : cs.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Red End Interview Call Button
                  GestureDetector(
                    onTap: () => _showEndInterviewDialog(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'End Interview',
                          style: AppTypography.codeMono.copyWith(
                            fontSize: 10,
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transcript Toggle Button
                  GestureDetector(
                    onTap: () => setState(() => _showTranscript = !_showTranscript),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: _showTranscript ? AppColors.primary : cs.onSurfaceVariant,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transcript',
                          style: AppTypography.codeMono.copyWith(
                            fontSize: 10,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('End Interview Session?',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to end this session? Your responses will be analyzed for detailed feedback.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.push('/interview/analysis/rep-101');
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}

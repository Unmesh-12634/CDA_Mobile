import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/cda_app_logo.dart';
import '../../../../shared/widgets/cda_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  // Manual entry only — never auto-filled from session or storage
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  int _currentStep = 1; // 1: Email, 2: OTP, 3: New Password, 4: Success
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  int _lockRemaining = 0;
  Timer? _lockTimer;
  int _otpValidityRemaining = 180; // 3 minutes = 180 seconds
  Timer? _otpValidityTimer;
  String? _localError;

  @override
  void initState() {
    super.initState();
    // Manual email entry: Listen to email input to detect if target email is locked
    _emailCtrl.addListener(_checkLockOnEmailChange);
  }

  void _checkLockOnEmailChange() {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isNotEmpty && email.contains('@')) {
      final remaining = ref.read(authProvider.notifier).getLockRemainingSeconds(email);
      if (remaining > 0 && remaining != _lockRemaining) {
        _startLockCountdown(remaining);
      } else if (remaining == 0 && _lockRemaining > 0) {
        _lockTimer?.cancel();
        setState(() {
          _lockRemaining = 0;
          _localError = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_checkLockOnEmailChange);
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _cooldownTimer?.cancel();
    _lockTimer?.cancel();
    _otpValidityTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _startLockCountdown(int seconds) {
    _lockTimer?.cancel();
    setState(() => _lockRemaining = seconds);
    if (seconds <= 0) return;

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockRemaining <= 1) {
        timer.cancel();
        setState(() {
          _lockRemaining = 0;
          _localError = null;
        });
        final email = _emailCtrl.text.trim().toLowerCase();
        if (email.isNotEmpty) {
          ref.read(authProvider.notifier).checkAndRefreshLock(email);
        }
      } else {
        setState(() => _lockRemaining--);
      }
    });
  }

  void _startOtpValidityCountdown([int seconds = 180]) {
    _otpValidityTimer?.cancel();
    setState(() => _otpValidityRemaining = seconds);
    if (seconds <= 0) return;

    _otpValidityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpValidityRemaining <= 1) {
        timer.cancel();
        setState(() {
          _otpValidityRemaining = 0;
          _localError = 'OTP has expired (3-minute limit). Please tap Resend OTP for a fresh code.';
        });
      } else {
        setState(() => _otpValidityRemaining--);
      }
    });
  }

  String _formatLockTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ── STEP 1: SEND OTP ───────────────────────────────────────
  void _handleSendOtp() async {
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);

    final email = _emailCtrl.text.trim().toLowerCase();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }

    // Check persistent 10-minute lockout
    final remaining = ref.read(authProvider.notifier).getLockRemainingSeconds(email);
    if (remaining > 0 || _lockRemaining > 0) {
      _startLockCountdown(remaining > 0 ? remaining : _lockRemaining);
      setState(() => _localError = 'Too many incorrect attempts. Please try again after 10 minutes.');
      return;
    }

    final success = await ref.read(authProvider.notifier).sendPasswordResetOtp(email);

    if (success && mounted) {
      _startCooldown(60);
      _startOtpValidityCountdown(180); // 3 minutes validity
      setState(() {
        _currentStep = 2;
        _localError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Verification OTP sent to $email (Valid for 3 mins)')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── STEP 2: VERIFY OTP ─────────────────────────────────────
  void _handleVerifyOtp() async {
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);

    final email = _emailCtrl.text.trim().toLowerCase();

    // Check persistent 10-minute lockout
    final remaining = ref.read(authProvider.notifier).getLockRemainingSeconds(email);
    if (remaining > 0 || _lockRemaining > 0) {
      _startLockCountdown(remaining > 0 ? remaining : _lockRemaining);
      setState(() => _localError = 'Too many incorrect attempts. Please try again after 10 minutes.');
      return;
    }

    // Check 3-minute OTP validity
    if (_otpValidityRemaining <= 0) {
      setState(() => _localError = 'OTP has expired (3-minute validity limit). Please tap Resend OTP for a fresh code.');
      return;
    }

    final otp = _otpCtrl.text.trim().replaceAll(' ', '');
    if (otp.length != 6 || int.tryParse(otp) == null) {
      setState(() => _localError = 'Please enter the complete 6-digit OTP code.');
      return;
    }

    final success = await ref.read(authProvider.notifier).verifyPasswordResetOtp(
          email: email,
          otp: otp,
        );

    if (success && mounted) {
      _lockTimer?.cancel();
      _otpValidityTimer?.cancel();
      setState(() {
        _currentStep = 3;
        _lockRemaining = 0;
        _otpValidityRemaining = 0;
        _localError = null;
      });
    } else if (mounted) {
      final lockSecs = ref.read(authProvider.notifier).getLockRemainingSeconds(email);
      if (lockSecs > 0) {
        _startLockCountdown(lockSecs);
      }
    }
  }

  // ── RESEND OTP ─────────────────────────────────────────────
  void _handleResendOtp() async {
    if (_resendCooldown > 0 || _lockRemaining > 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);

    final email = _emailCtrl.text.trim().toLowerCase();

    // Check persistent 10-minute lockout
    final remaining = ref.read(authProvider.notifier).getLockRemainingSeconds(email);
    if (remaining > 0 || _lockRemaining > 0) {
      _startLockCountdown(remaining > 0 ? remaining : _lockRemaining);
      setState(() => _localError = 'Too many incorrect attempts. Please try again after 10 minutes.');
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .sendPasswordResetOtp(email);

    if (success && mounted) {
      _startCooldown(60);
      _startOtpValidityCountdown(180); // Reset 3-minute validity timer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('A fresh 6-digit OTP has been sent (Valid for 3 mins).')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── STEP 3: RESET PASSWORD ─────────────────────────────────
  void _handleResetPassword() async {
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);

    final newPass = _newPasswordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;

    if (newPass.length < 6) {
      setState(() => _localError = 'Password must be at least 6 characters.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _localError = 'Passwords do not match. Please verify.');
      return;
    }

    final success = await ref.read(authProvider.notifier).completePasswordReset(newPass);

    if (success && mounted) {
      setState(() {
        _currentStep = 4;
        _localError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final displayedError = _localError ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep == 4
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppColors.onSurface,
                  size: 20,
                ),
                onPressed: () {
                  if (_currentStep == 2) {
                    setState(() => _currentStep = 1);
                  } else if (_currentStep == 3) {
                    setState(() => _currentStep = 2);
                  } else {
                    ref.read(authProvider.notifier).resetRecoveryState();
                    context.pop();
                  }
                },
              ),
        title: Text(
          _appBarTitle(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const CDAAppLogo(size: CDALogoSize.medium),
                  const SizedBox(height: 24),

                  // Step Progression Indicator
                  if (_currentStep < 4) ...[
                    _buildStepIndicator(isDark),
                    const SizedBox(height: 24),
                  ],

                  // Header Title & Subtitle
                  Text(
                    _stepTitle(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stepSubtitle(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Banner
                  if (displayedError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayedError,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Content Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildCurrentStepContent(isDark, authState),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer Back to Login
                  if (_currentStep < 4)
                    TextButton(
                      onPressed: () {
                        ref.read(authProvider.notifier).resetRecoveryState();
                        context.go('/login');
                      },
                      child: Text(
                        'Remember your password? Sign In',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.credNeonCyan : AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── STEP INDICATOR ─────────────────────────────────────────
  Widget _buildStepIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepBadge(step: 1, label: 'Email', isActive: _currentStep >= 1, isDark: isDark),
        _buildStepConnector(isActive: _currentStep >= 2, isDark: isDark),
        _buildStepBadge(step: 2, label: 'OTP', isActive: _currentStep >= 2, isDark: isDark),
        _buildStepConnector(isActive: _currentStep >= 3, isDark: isDark),
        _buildStepBadge(step: 3, label: 'Password', isActive: _currentStep >= 3, isDark: isDark),
      ],
    );
  }

  Widget _buildStepBadge({
    required int step,
    required String label,
    required bool isActive,
    required bool isDark,
  }) {
    final activeColor = isDark ? const Color(0xFF818CF8) : AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            border: Border.all(
              color: isActive ? activeColor : inactiveColor,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? (isDark ? Colors.white : AppColors.onSurface) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isActive, required bool isDark}) {
    final activeColor = isDark ? const Color(0xFF818CF8) : AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
      color: isActive ? activeColor : inactiveColor,
    );
  }

  // ── CURRENT STEP CONTENT DISPATCHER ─────────────────────────
  Widget _buildCurrentStepContent(bool isDark, AuthState authState) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Email(isDark, authState);
      case 2:
        return _buildStep2Otp(isDark, authState);
      case 3:
        return _buildStep3NewPassword(isDark, authState);
      case 4:
      default:
        return _buildStep4Success(isDark);
    }
  }

  // ── LOCK WARNING BANNER ─────────────────────────────────────
  Widget _buildLockWarningBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Account Temporarily Locked',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _formatLockTime(_lockRemaining),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Too many incorrect attempts. Please try again after 10 minutes.',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: EMAIL UI ───────────────────────────────────────
  Widget _buildStep1Email(bool isDark, AuthState authState) {
    final isLocked = _lockRemaining > 0 || authState.isLocked;

    return Column(
      key: const ValueKey('step_1_email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLocked) _buildLockWarningBanner(isDark),
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => isLocked ? null : _handleSendOtp(),
          style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'name@example.com',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: isDark ? AppColors.credNeonCyan : AppColors.primary,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CDAButton(
          label: isLocked ? 'Locked (10m) 🔒' : 'Send OTP 🚀',
          variant: isLocked ? CDAButtonVariant.ghost : CDAButtonVariant.primary,
          isLoading: authState.isLoading,
          isFullWidth: true,
          onTap: isLocked ? null : _handleSendOtp,
        ),
      ],
    );
  }

  // ── STEP 2: OTP VERIFICATION UI ─────────────────────────────
  Widget _buildStep2Otp(bool isDark, AuthState authState) {
    final isLocked = _lockRemaining > 0 || authState.isLocked;
    final isExpired = _otpValidityRemaining <= 0;

    return Column(
      key: const ValueKey('step_2_otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLocked) _buildLockWarningBanner(isDark),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '6-Digit OTP Code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: !isExpired
                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: !isExpired
                          ? (isDark ? AppColors.credNeonCyan.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3))
                          : AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        !isExpired ? Icons.timer_outlined : Icons.timer_off_outlined,
                        size: 12,
                        color: !isExpired
                            ? (isDark ? AppColors.credNeonCyan : AppColors.primary)
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        !isExpired
                            ? _formatLockTime(_otpValidityRemaining)
                            : 'Expired (3m)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: !isExpired
                              ? (isDark ? AppColors.credNeonCyan : AppColors.primary)
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => setState(() => _currentStep = 1),
              child: Text(
                'Change Email',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.credNeonCyan : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          enabled: !isLocked && !isExpired,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => (isLocked || isExpired) ? null : _handleVerifyOtp(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 10,
            color: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: TextStyle(
              letterSpacing: 10,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            prefixIcon: Icon(
              Icons.pin_outlined,
              color: isDark ? AppColors.credNeonCyan : AppColors.primary,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        if (authState.otpAttempts > 0 && !isLocked) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                '${3 - authState.otpAttempts} attempt(s) remaining before 10m lock',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        CDAButton(
          label: isLocked
              ? 'Verification Locked 🔒'
              : (isExpired ? 'OTP Expired (Please Resend)' : 'Verify OTP 🔑'),
          variant: (isLocked || isExpired) ? CDAButtonVariant.ghost : CDAButtonVariant.primary,
          isLoading: authState.isLoading,
          isFullWidth: true,
          onTap: (isLocked || isExpired) ? null : _handleVerifyOtp,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: (_resendCooldown == 0 && !isLocked) ? _handleResendOtp : null,
            icon: Icon(
              Icons.refresh_rounded,
              size: 16,
              color: (_resendCooldown == 0 && !isLocked)
                  ? (isDark ? AppColors.credNeonCyan : AppColors.primary)
                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            ),
            label: Text(
              isLocked
                  ? 'Resend Locked (${_formatLockTime(_lockRemaining)})'
                  : (_resendCooldown == 0
                      ? 'Resend OTP'
                      : 'Resend OTP in ${_resendCooldown}s'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: (_resendCooldown == 0 && !isLocked)
                    ? (isDark ? AppColors.credNeonCyan : AppColors.primary)
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 3: NEW PASSWORD UI ─────────────────────────────────
  Widget _buildStep3NewPassword(bool isDark, AuthState authState) {
    return Column(
      key: const ValueKey('step_3_new_password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordCtrl,
          obscureText: _obscurePass,
          style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Enter at least 6 characters',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: isDark ? AppColors.credNeonCyan : AppColors.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Confirm New Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordCtrl,
          obscureText: _obscureConfirmPass,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleResetPassword(),
          style: TextStyle(color: isDark ? Colors.white : AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Re-enter your new password',
            prefixIcon: Icon(
              Icons.lock_reset_rounded,
              color: isDark ? AppColors.credNeonCyan : AppColors.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CDAButton(
          label: 'Reset Password 🛡️',
          variant: CDAButtonVariant.primary,
          isLoading: authState.isLoading,
          isFullWidth: true,
          onTap: _handleResetPassword,
        ),
      ],
    );
  }

  // ── STEP 4: SUCCESS UI ──────────────────────────────────────
  Widget _buildStep4Success(bool isDark) {
    return Column(
      key: const ValueKey('step_4_success'),
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: AppColors.success, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Password Reset Successful',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your password has been successfully updated. You can now sign in using your new credentials.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        CDAButton(
          label: 'Go to Login 🔑',
          variant: CDAButtonVariant.primary,
          isFullWidth: true,
          onTap: () {
            ref.read(authProvider.notifier).resetRecoveryState();
            context.go('/login');
          },
        ),
      ],
    );
  }

  // ── HELPER TITLES ───────────────────────────────────────────
  String _appBarTitle() {
    switch (_currentStep) {
      case 1:
        return 'Forgot Password';
      case 2:
        return 'Verify OTP';
      case 3:
        return 'Create Password';
      case 4:
      default:
        return 'Success';
    }
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Reset Your Password';
      case 2:
        return 'Verify OTP';
      case 3:
        return 'Create New Password';
      case 4:
      default:
        return 'All Done!';
    }
  }

  String _stepSubtitle() {
    switch (_currentStep) {
      case 1:
        return "Enter your registered email address and we'll send you a verification OTP.";
      case 2:
        return 'Enter the 6-digit OTP sent to ${_emailCtrl.text.trim()}.';
      case 3:
        return 'Set a strong new password for your account.';
      case 4:
      default:
        return 'Your password was successfully updated.';
    }
  }
}

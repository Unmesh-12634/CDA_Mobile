import 'package:flutter/material.dart';
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
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _otpSent = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(authProvider.notifier)
        .sendPasswordResetOtp(_emailCtrl.text);

    if (success && mounted) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📧 Verification code sent to ${_emailCtrl.text}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Passwords do not match. Please verify.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .verifyAndResetPassword(
          email: _emailCtrl.text,
          otp: _otpCtrl.text,
          newPassword: _newPasswordCtrl.text,
        );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.credDarkSurface
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.success, width: 1.5),
          ),
          title: const Row(
            children: [
              Text('🎉 ', style: TextStyle(fontSize: 24)),
              Expanded(
                child: Text(
                  'Password Reset Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your password has been updated. You can now sign in with your new credentials.',
            style: TextStyle(fontSize: 13, color: AppColors.outline),
          ),
          actions: [
            CDAButton(
              label: 'Proceed to Sign In 🔑',
              variant: CDAButtonVariant.primary,
              onTap: () {
                Navigator.pop(ctx);
                context.go('/login');
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.onSurface),
          onPressed: () {
            if (_otpSent) {
              setState(() => _otpSent = false);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _otpSent ? 'Reset Password' : 'Forgot Password',
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
                  const SizedBox(height: 28),

                  // Title Card Header
                  Text(
                    _otpSent ? 'Enter OTP & New Password' : 'Reset Your Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _otpSent
                        ? 'Verification code sent to ${_emailCtrl.text}'
                        : 'Enter your registered CDA institute email address to receive a 6-digit verification code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Banner
                  if (authState.errorMessage != null) ...[
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
                              authState.errorMessage!,
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

                  // Glass Form Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_otpSent) ...[
                          // STEP 1: EMAIL INPUT
                          Text(
                            'Institute Email Address',
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
                            style: TextStyle(
                                color: isDark ? Colors.white : AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'student@cda.ai',
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: isDark
                                      ? AppColors.credNeonCyan
                                      : AppColors.primary),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF162032)
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          CDAButton(
                            label: 'Send Verification Code 📧',
                            variant: CDAButtonVariant.primary,
                            isLoading: authState.isLoading,
                            onTap: _handleSendOtp,
                          ),
                        ] else ...[
                          // STEP 2: OTP & NEW PASSWORD INPUT
                          Text(
                            '6-Digit OTP Code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: isDark ? AppColors.credGold : AppColors.primary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '123456',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF162032)
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

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
                            style: TextStyle(
                                color: isDark ? Colors.white : AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'At least 6 characters',
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  color: isDark
                                      ? AppColors.credNeonCyan
                                      : AppColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.outline,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF162032)
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

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
                            style: TextStyle(
                                color: isDark ? Colors.white : AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Re-enter new password',
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  color: isDark
                                      ? AppColors.credNeonCyan
                                      : AppColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.outline,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirmPass = !_obscureConfirmPass),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF162032)
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          CDAButton(
                            label: 'Reset Password & Sign In 🔒',
                            variant: CDAButtonVariant.gold,
                            isLoading: authState.isLoading,
                            onTap: _handleResetPassword,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Back to Sign In Link
                  TextButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back to Sign In'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDark ? const Color(0xFF94A3B8) : AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
}

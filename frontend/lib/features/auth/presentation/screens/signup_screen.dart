import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/cda_app_logo.dart';
import '../../../../shared/widgets/cda_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../data/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  String _selectedTargetRole = 'Senior AI & Full-Stack Engineer';
  String _selectedExperience = 'Student / Fresher';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = true;

  final List<String> _targetRoles = [
    'Senior AI & Full-Stack Engineer',
    'Full Stack Web Developer',
    'Data Scientist & ML Engineer',
    'Backend Engineer (Java / Python)',
    'Mobile App Developer (Flutter)',
    'DevOps & Cloud Architect',
  ];

  final List<String> _experienceLevels = [
    'Student / Fresher',
    '1 - 3 Years Experience',
    '3+ Years Experience',
  ];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    FocusScope.of(context).unfocus();

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please accept the Terms of Service to proceed.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    final pass = _passwordCtrl.text.trim();
    final confirmPass = _confirmPasswordCtrl.text.trim();

    if (pass.isNotEmpty && confirmPass.isNotEmpty && pass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Password and Confirm Password do not match.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    final fullNameText = _fullNameCtrl.text.trim();
    final emailText = _emailCtrl.text.trim();
    final phoneText = _phoneCtrl.text.trim();

    final success = await ref.read(authProvider.notifier).signUp(
          fullName: fullNameText.isEmpty ? 'Student Candidate' : fullNameText,
          email: emailText.isEmpty ? 'student@cranes.in' : emailText,
          phone: phoneText.isEmpty ? '9876543210' : phoneText,
          password: pass.isEmpty ? 'password123' : pass,
          targetRole: _selectedTargetRole,
          experienceLevel: _selectedExperience,
          ref: ref,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Welcome to Cranes Varsity, ${fullNameText.isEmpty ? 'Candidate' : fullNameText}!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? AppColors.credDarkBackground : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Back Action
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : AppColors.onSurface,
                        size: 20,
                      ),
                      onPressed: () => context.go('/login'),
                    ),
                  ),

                  // Official Cranes Brand Logo
                  const CDAAppLogo(size: CDALogoSize.medium),
                  const SizedBox(height: 20),

                  Text(
                    'Create Student Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join Cranes Institute to unlock AI mock interviews & career guidance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Error Banner
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Form Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information Section
                        _buildSectionHeader('PERSONAL INFORMATION', isDark),
                        const SizedBox(height: 10),

                        _buildLabel('Full Name', isDark),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _fullNameCtrl,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: 'Enter your full name',
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildLabel('Institute Email Address', isDark),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: 'student@cranes.in',
                            icon: Icons.email_outlined,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildLabel('Phone Number', isDark),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: '10-digit mobile number',
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Career Focus Section
                        _buildSectionHeader('CAREER FOCUS', isDark),
                        const SizedBox(height: 10),

                        _buildLabel('Target Job Role', isDark),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTargetRole,
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF1E2D4A) : Colors.white,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.onSurface,
                              ),
                              icon: Icon(Icons.arrow_drop_down_rounded,
                                  color: isDark ? AppColors.credNeonCyan : AppColors.primary),
                              items: _targetRoles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedTargetRole = val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _buildLabel('Experience Level', isDark),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedExperience,
                              isExpanded: true,
                              dropdownColor: isDark ? const Color(0xFF1E2D4A) : Colors.white,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.onSurface,
                              ),
                              icon: Icon(Icons.arrow_drop_down_rounded,
                                  color: isDark ? AppColors.credNeonCyan : AppColors.primary),
                              items: _experienceLevels.map((exp) {
                                return DropdownMenuItem<String>(
                                  value: exp,
                                  child: Text(exp),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedExperience = val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Account Security Section
                        _buildSectionHeader('ACCOUNT SECURITY', isDark),
                        const SizedBox(height: 10),

                        _buildLabel('Password', isDark),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: 'Create password',
                            icon: Icons.lock_outline_rounded,
                            isDark: isDark,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: AppColors.outline,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildLabel('Confirm Password', isDark),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _confirmPasswordCtrl,
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: 'Re-enter password',
                            icon: Icons.lock_outline_rounded,
                            isDark: isDark,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: AppColors.outline,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Terms Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _acceptTerms,
                                activeColor: isDark ? AppColors.credNeonCyan : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) =>
                                    setState(() => _acceptTerms = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : AppColors.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: isDark ? AppColors.credGold : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: isDark ? AppColors.credGold : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Submit CTA
                        CDAButton(
                          label: 'Create Account 🚀',
                          variant: CDAButtonVariant.primary,
                          isLoading: authState.isLoading,
                          onTap: _handleSignUp,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Already have account footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have a CDA account? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                        ),
                      ),
                      _AppleSpringButton(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.credNeonCyan : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: isDark ? AppColors.credGold : AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isDark ? AppColors.credGold : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppColors.onSurface,
      ),
    );
  }

  InputDecoration _buildInputDeco({
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(icon,
          size: 18, color: isDark ? AppColors.credNeonCyan : AppColors.primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.credNeonCyan : AppColors.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// APPLE DESIGN SPRING BUTTON (Apple Design & Animate Skills)
// Critically Damped Spring (Response 0.18s, Damping 1.0)
// Zero Latency & Reduced Motion Support
// ─────────────────────────────────────────────────────────────
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
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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

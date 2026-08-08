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
  final _fullNameCtrl = TextEditingController(text: 'Arjun Verma');
  final _emailCtrl = TextEditingController(text: 'arjun.verma@cranes.in');
  final _phoneCtrl = TextEditingController(text: '9876543210');
  final _passwordCtrl = TextEditingController(text: 'password123');
  final _confirmPasswordCtrl = TextEditingController(text: 'password123');

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
        const SnackBar(
          content: Text('⚠️ Please accept the Terms of Service to proceed.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Password and Confirm Password do not match.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).signUp(
          fullName: _fullNameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          password: _passwordCtrl.text,
          targetRole: _selectedTargetRole,
          experienceLevel: _selectedExperience,
          ref: ref,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Welcome to Cranes Varsity, ${_fullNameCtrl.text}!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
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
      backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top App Bar / Back row
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
                  const CDAAppLogo(size: CDALogoSize.large),
                  const SizedBox(height: 16),

                  Text(
                    'Create Student Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join Cranes Varsity to unlock AI mock interviews & career guidance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
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

                  // Glass Form Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        _buildSectionHeader('PERSONAL DETAILS', isDark),
                        const SizedBox(height: 8),
                        _buildLabel('Full Name', isDark),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _fullNameCtrl,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: 'Arjun Verma',
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Email Address
                        _buildLabel('Institute Email Address', isDark),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: 'arjun.verma@cranes.in',
                            icon: Icons.email_outlined,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mobile Phone Number
                        _buildLabel('Mobile Phone Number', isDark),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: '9876543210',
                            icon: Icons.phone_android_rounded,
                            isDark: isDark,
                            prefixText: '+91 ',
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Career Goals Section
                        _buildSectionHeader('CAREER PREFERENCES', isDark),
                        const SizedBox(height: 8),
                        _buildLabel('Target Role / Career Goal', isDark),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedTargetRole,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF162032) : Colors.white,
                          style: TextStyle(
                              color: isDark ? Colors.white : AppColors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          decoration: _buildInputDeco(
                            hint: 'Select target role',
                            icon: Icons.work_outline_rounded,
                            isDark: isDark,
                          ),
                          items: _targetRoles
                              .map((role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedTargetRole = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildLabel('Experience Level', isDark),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _selectedExperience,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF162032) : Colors.white,
                          style: TextStyle(
                              color: isDark ? Colors.white : AppColors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          decoration: _buildInputDeco(
                            hint: 'Select experience',
                            icon: Icons.workspace_premium_rounded,
                            isDark: isDark,
                          ),
                          items: _experienceLevels
                              .map((exp) => DropdownMenuItem(
                                    value: exp,
                                    child: Text(exp),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedExperience = val);
                          },
                        ),
                        const SizedBox(height: 18),

                        // Security Section
                        _buildSectionHeader('ACCOUNT SECURITY', isDark),
                        const SizedBox(height: 8),
                        _buildLabel('Password', isDark),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            isDark: isDark,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.outline,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildLabel('Confirm Password', isDark),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _confirmPasswordCtrl,
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.onSurface),
                          decoration: _buildInputDeco(
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            isDark: isDark,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.outline,
                                size: 18,
                              ),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Terms & Conditions Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _acceptTerms,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) =>
                                    setState(() => _acceptTerms = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'I agree to Cranes Terms of Service & Privacy Policy',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Action CTA
                        CDAButton(
                          label: 'Create Account & Get 3 Free Trials 🚀',
                          variant: CDAButtonVariant.gold,
                          isLoading: authState.isLoading,
                          onTap: _handleSignUp,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Already have an account Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have a Cranes account? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        color: isDark ? AppColors.credGold : AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.onSurface,
      ),
    );
  }

  InputDecoration _buildInputDeco({
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.credNeonCyan : AppColors.primary,
      ),
      prefixIcon: Icon(
        icon,
        color: isDark ? AppColors.credNeonCyan : AppColors.primary,
        size: 18,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

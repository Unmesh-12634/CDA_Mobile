import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../../shared/widgets/cda_app_logo.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../profile/data/user_profile_provider.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Apple fluid spring entrance curve (0.95 -> 1.0)
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );

    _animCtrl.forward();

    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    _timer = Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;

      final session = SupabaseConfig.client.auth.currentSession;
      final authState = ref.read(authProvider);
      final isLocalLoggedIn = LocalCacheService().get<bool>('cda_auth_logged_in') ?? false;
      final cachedEmail = LocalCacheService().get<String>('cda_auth_email');

      final String? activeEmail = session?.user.email ??
          (authState.isAuthenticated && authState.email.isNotEmpty ? authState.email : null) ??
          (isLocalLoggedIn && cachedEmail != null && cachedEmail.isNotEmpty ? cachedEmail : null);

      if (activeEmail != null && activeEmail.isNotEmpty) {
        debugPrint('🚀 [Auto-Login] Active persistent session found for $activeEmail. Navigating directly to /home');
        ref.read(userProfileProvider.notifier).refreshProfileFromDb(activeEmail);
        if (mounted) {
          context.go('/home');
        }
      } else {
        debugPrint('🔒 [Auth Required] No active session found. Navigating to /login');
        if (mounted) {
          context.go('/login');
        }
      }
    });
  }



  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
      body: Stack(
        children: [
          // Ambient Glow Accent in Background
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 90,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Official Cranes Brand App Logo with Glass Elevation
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.08),
                            blurRadius: 36,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: const CDAAppLogo(
                        size: CDALogoSize.large,
                        showText: true,
                        showTagline: true,
                      ),
                    ),

                    const Spacer(),

                    // Elegant Progress Spinner
                    Column(
                      children: [
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.8,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'AI Interview & Career Engine...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 44),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

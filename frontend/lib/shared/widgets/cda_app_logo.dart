import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum CDALogoSize { small, medium, large }

class CDAAppLogo extends StatelessWidget {
  final CDALogoSize size;
  final bool showText;
  final bool showTagline;

  const CDAAppLogo({
    super.key,
    this.size = CDALogoSize.medium,
    this.showText = true,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double logoWidth;
    double logoHeight;
    double taglineSize;

    switch (size) {
      case CDALogoSize.small:
        logoWidth = 48.0;
        logoHeight = 48.0;
        taglineSize = 8.5;
        break;
      case CDALogoSize.large:
        logoWidth = 100.0;
        logoHeight = 100.0;
        taglineSize = 11.0;
        break;
      case CDALogoSize.medium:
        logoWidth = 72.0;
        logoHeight = 72.0;
        taglineSize = 10.0;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Official Cranes Logo Badge Container
        Container(
          width: logoWidth,
          height: logoHeight,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.20),
                blurRadius: size == CDALogoSize.large ? 20 : 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF4648D4).withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Image.asset(
            'assets/images/cranes_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback icon if asset fails loading
              return const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 32,
              );
            },
          ),
        ),

        if (showText) ...[
          const SizedBox(height: 10),

          // Official Cranes Brand Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CRANES',
                style: TextStyle(
                  fontSize: size == CDALogoSize.large ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '®',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.credGold : const Color(0xFF003399),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  gradient: AppColors.credGoldGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Text(
                  'ACADEMY',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),

          if (showTagline) ...[
            const SizedBox(height: 3),
            Text(
              'INSTITUTE OF CAREER & AI EXCELLENCE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: taglineSize,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

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
    double titleFontSize;

    switch (size) {
      case CDALogoSize.small:
        logoWidth = 36.0;
        logoHeight = 36.0;
        taglineSize = 8.0;
        titleFontSize = 15.0;
        break;
      case CDALogoSize.medium:
        logoWidth = 52.0;
        logoHeight = 52.0;
        taglineSize = 9.5;
        titleFontSize = 18.0;
        break;
      case CDALogoSize.large:
        logoWidth = 64.0;
        logoHeight = 64.0;
        taglineSize = 10.5;
        titleFontSize = 21.0;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Official Cranes Logo Badge Container (Compact & Elegant)
        Container(
          width: logoWidth,
          height: logoHeight,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.30 : 0.15),
                blurRadius: size == CDALogoSize.large ? 16 : 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: const Color(0xFF0F2088).withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Image.asset(
            'assets/images/cranes_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 28,
              );
            },
          ),
        ),

        if (showText) ...[
          const SizedBox(height: 8),

          // Official Brand Title: CRANES VARSITY
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CRANES ',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 1.5,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFF0F2088)],
                ).createShader(bounds),
                child: Text(
                  'VARSITY',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),

          if (showTagline) ...[
            const SizedBox(height: 3),
            Text(
              'Where Technology Meets Excellence',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: taglineSize,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

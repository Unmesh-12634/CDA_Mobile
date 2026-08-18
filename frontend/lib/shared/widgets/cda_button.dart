import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CDA CRED-STYLE BUTTON SYSTEM
// Inspired by CRED's premium dark UI buttons:
//   Primary  → indigo/electric gradient pill — main CTAs
//   Gold     → amber gradient pill — rewards / earn actions
//   Ghost    → frosted-glass pill with electric border — secondary actions
//   Minimal  → transparent, text-only, underline accent
// ─────────────────────────────────────────────────────────────────────────────

enum CDAButtonVariant { primary, gold, ghost, minimal }

class CDAButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final CDAButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final double fontSize;

  const CDAButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = CDAButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50,
    this.fontSize = 14,
  });

  // Named constructors for convenience
  const CDAButton.primary({
    super.key,
    required this.label,
    this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50,
    this.fontSize = 14,
  }) : variant = CDAButtonVariant.primary;

  const CDAButton.gold({
    super.key,
    required this.label,
    this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50,
    this.fontSize = 14,
  }) : variant = CDAButtonVariant.gold;

  const CDAButton.ghost({
    super.key,
    required this.label,
    this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50,
    this.fontSize = 14,
  }) : variant = CDAButtonVariant.ghost;

  const CDAButton.minimal({
    super.key,
    required this.label,
    this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 44,
    this.fontSize = 13,
  }) : variant = CDAButtonVariant.minimal;

  @override
  State<CDAButton> createState() => _CDAButtonState();
}

class _CDAButtonState extends State<CDAButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onTap != null) _ctrl.forward();
  }

  void _onTapUp(_) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: _buildButtonSurface(isDark, disabled),
        ),
      ),
    );
  }

  Widget _buildButtonSurface(bool isDark, bool disabled) {
    switch (widget.variant) {
      case CDAButtonVariant.primary:
        return _PrimaryButton(
          label: widget.label,
          leadingIcon: widget.leadingIcon,
          trailingIcon: widget.trailingIcon,
          isLoading: widget.isLoading,
          isFullWidth: widget.isFullWidth,
          width: widget.width,
          height: widget.height,
          fontSize: widget.fontSize,
          disabled: disabled,
          isDark: isDark,
          glowT: _glow.value,
        );
      case CDAButtonVariant.gold:
        return _GoldButton(
          label: widget.label,
          leadingIcon: widget.leadingIcon,
          trailingIcon: widget.trailingIcon,
          isLoading: widget.isLoading,
          isFullWidth: widget.isFullWidth,
          width: widget.width,
          height: widget.height,
          fontSize: widget.fontSize,
          disabled: disabled,
        );
      case CDAButtonVariant.ghost:
        return _GhostButton(
          label: widget.label,
          leadingIcon: widget.leadingIcon,
          trailingIcon: widget.trailingIcon,
          isLoading: widget.isLoading,
          isFullWidth: widget.isFullWidth,
          width: widget.width,
          height: widget.height,
          fontSize: widget.fontSize,
          disabled: disabled,
          isDark: isDark,
        );
      case CDAButtonVariant.minimal:
        return _MinimalButton(
          label: widget.label,
          leadingIcon: widget.leadingIcon,
          isLoading: widget.isLoading,
          isFullWidth: widget.isFullWidth,
          fontSize: widget.fontSize,
          disabled: disabled,
        );
    }
  }
}

// ─── PRIMARY: deep indigo → electric-blue gradient pill ──────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final double fontSize;
  final bool disabled;
  final bool isDark;
  final double glowT;

  const _PrimaryButton({
    required this.label, required this.isLoading, required this.isFullWidth,
    required this.height, required this.fontSize, required this.disabled,
    required this.isDark, required this.glowT,
    this.leadingIcon, this.trailingIcon, this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.48 : 1.0,
      child: Container(
        width: isFullWidth ? double.infinity : width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2088), Color(0xFF1E35B3), Color(0xFF2848D0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2088).withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF1E35B3).withValues(alpha: 0.15 * glowT),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _ButtonContent(
          label: label,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          isLoading: isLoading,
          textColor: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── GOLD: amber → warm-yellow gradient pill (rewards / coins) ───────────────
class _GoldButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final double fontSize;
  final bool disabled;

  const _GoldButton({
    required this.label, required this.isLoading, required this.isFullWidth,
    required this.height, required this.fontSize, required this.disabled,
    this.leadingIcon, this.trailingIcon, this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.48 : 1.0,
      child: Container(
        width: isFullWidth ? double.infinity : width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: AppColors.credGoldGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.credGold.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _ButtonContent(
          label: label,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          isLoading: isLoading,
          textColor: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─── GHOST: frosted-glass pill with electric border ──────────────────────────
class _GhostButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final double fontSize;
  final bool disabled;
  final bool isDark;

  const _GhostButton({
    required this.label, required this.isLoading, required this.isFullWidth,
    required this.height, required this.fontSize, required this.disabled,
    required this.isDark, this.leadingIcon, this.trailingIcon, this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.48 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: isFullWidth ? double.infinity : width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: isDark
                  ? const Color(0xFF0F2088).withValues(alpha: 0.15)
                  : const Color(0xFF0F2088).withValues(alpha: 0.06),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF6082EC).withValues(alpha: 0.45)
                    : const Color(0xFF0F2088).withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: _ButtonContent(
              label: label,
              leadingIcon: leadingIcon,
              trailingIcon: trailingIcon,
              isLoading: isLoading,
              textColor: isDark ? const Color(0xFF818CF8) : AppColors.primary,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MINIMAL: transparent text pill ─────────────────────────────────────────
class _MinimalButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double fontSize;
  final bool disabled;

  const _MinimalButton({
    required this.label, required this.isLoading, required this.isFullWidth,
    required this.fontSize, required this.disabled, this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 15,
                color: isDark ? const Color(0xFF818CF8) : AppColors.primary),
              const SizedBox(width: 5),
            ],
            if (isLoading)
              SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                ),
              )
            else
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: (isDark
                      ? const Color(0xFF818CF8)
                      : AppColors.primary).withValues(alpha: 0.4),
                  decorationThickness: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared inner content layout ─────────────────────────────────────────────
class _ButtonContent extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.textColor,
    required this.fontSize,
    required this.fontWeight,
    required this.letterSpacing,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: isLoading
            ? SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: textColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, color: textColor, size: 16),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        letterSpacing: letterSpacing,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 7),
                    Icon(trailingIcon, color: textColor, size: 16),
                  ],
                ],
              ),
      ),
    );
  }
}

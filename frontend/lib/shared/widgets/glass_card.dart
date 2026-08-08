import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// CRED-style glass card.
///
/// Light mode  → crisp white with a soft shadow and hairline border
/// Dark mode   → pure obsidian glass with metallic electric border glow,
///               subtle BackdropFilter blur, and high contrast content
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = AppConstants.radiusLg,
    this.backgroundColor,
    this.border,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ?? const EdgeInsets.all(AppConstants.paddingLg);
    final effectiveMargin = widget.margin ?? EdgeInsets.zero;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Dark: CRED Obsidian Glass ─────────────────────────────
    final darkBg = widget.backgroundColor
        ?? AppColors.credDarkCard.withValues(alpha: 0.85);
    const darkBorderColor = AppColors.credDarkBorder;

    // ── Light: Crisp white with gentle shadow ───────────────────────────
    final lightBg = widget.backgroundColor ?? Colors.white;
    const lightBorderColor = Color(0xFFE2E8F0);

    final radius = BorderRadius.circular(widget.borderRadius);

    Widget inner = Container(
      margin: effectiveMargin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: isDark ? darkBg : lightBg,
        borderRadius: radius,
        border: widget.border ?? Border.all(
          color: isDark ? darkBorderColor : lightBorderColor,
          width: 1.0,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: widget.child,
    );

    Widget content = AnimatedScale(
      scale: _isPressed && widget.onTap != null ? 0.98 : 1.0,
      duration: AppConstants.animationFast,
      curve: Curves.easeOutCubic,
      child: inner,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

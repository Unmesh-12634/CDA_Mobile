import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_typography.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;
  final bool isLoading;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = AppConstants.minTouchTarget,
    this.isLoading = false,
    this.gradient,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.gradient ?? AppColors.primaryGradient;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed && !isDisabled ? 0.97 : 1.0,
        duration: AppConstants.animationFast,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: isDisabled ? null : effectiveGradient,
            color: isDisabled ? AppColors.surfaceContainerHigh : null,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

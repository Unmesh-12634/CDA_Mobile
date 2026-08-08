import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

void showComingSoonSnackBar(BuildContext context, [String? featureName]) {
  final label = featureName != null ? '$featureName coming soon!' : 'Feature coming soon!';
  showAppSnackBar(
    context,
    message: label,
    icon: Icons.info_outline_rounded,
    backgroundColor: AppColors.primary,
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  showAppSnackBar(
    context,
    message: message,
    icon: Icons.check_circle_rounded,
    backgroundColor: const Color(0xFF10B981),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  showAppSnackBar(
    context,
    message: message,
    icon: Icons.error_outline_rounded,
    backgroundColor: const Color(0xFFEF4444),
  );
}

void showAppSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.notifications_active_rounded,
  Color backgroundColor = AppColors.primary,
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      duration: duration,
    ),
  );
}

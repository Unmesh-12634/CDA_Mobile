import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/data/user_settings_provider.dart';

/// Centralized Haptic Engine respecting user preferences
class AppHaptics {
  AppHaptics._();

  /// Light tap impact (used for tabs, chips, option selections)
  static void lightImpact(WidgetRef? ref) {
    if (ref == null) {
      HapticFeedback.lightImpact();
      return;
    }
    final enabled = ref.read(userSettingsProvider).hapticFeedback;
    if (enabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Medium tap impact (used for submitting answers, starting interviews)
  static void mediumImpact(WidgetRef? ref) {
    if (ref == null) {
      HapticFeedback.mediumImpact();
      return;
    }
    final enabled = ref.read(userSettingsProvider).hapticFeedback;
    if (enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Heavy impact (used for toggling haptics ON or completing milestone)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Subtle selection tick (used for sliders, drop-down items)
  static void selectionClick(WidgetRef? ref) {
    if (ref == null) {
      HapticFeedback.selectionClick();
      return;
    }
    final enabled = ref.read(userSettingsProvider).hapticFeedback;
    if (enabled) {
      HapticFeedback.selectionClick();
    }
  }
}

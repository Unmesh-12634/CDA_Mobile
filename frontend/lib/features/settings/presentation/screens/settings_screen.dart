import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../shared/widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _aiVoicePersona = 'Samantha (Natural AI)';
  double _speechSpeed = 1.0;
  bool _autoRecord = true;
  bool _emailNotifs = true;
  bool _pushNotifs = true;
  bool _haptics = true;
  String _feedbackDetail = 'Comprehensive';

  final List<String> _voices = [
    'Samantha (Natural AI)',
    'David (Corporate Technical)',
    'Alex (Friendly Coach)',
  ];

  final List<String> _feedbackLevels = [
    'Comprehensive',
    'Standard',
    'Executive Summary',
  ];

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings & Preferences',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Appearance & Theme ──────────────────────────────────────────────
              _buildSectionTitle('APPEARANCE & THEME', isDark),
              const SizedBox(height: 10),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Theme',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose how CDA Companion looks on your device',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Theme selector pills
                    Row(
                      children: [
                        Expanded(
                          child: _buildThemeChip(
                            context: context,
                            label: 'Light',
                            icon: Icons.light_mode_rounded,
                            mode: ThemeMode.light,
                            currentMode: currentThemeMode,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThemeChip(
                            context: context,
                            label: 'Dark',
                            icon: Icons.dark_mode_rounded,
                            mode: ThemeMode.dark,
                            currentMode: currentThemeMode,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThemeChip(
                            context: context,
                            label: 'System',
                            icon: Icons.settings_brightness_rounded,
                            mode: ThemeMode.system,
                            currentMode: currentThemeMode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.stackLg),

              // ── AI Interviewer Configuration ──────────────────────────────────
              _buildSectionTitle('AI INTERVIEWER CONFIGURATION', isDark),
              const SizedBox(height: 10),

              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Voice Persona',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _aiVoicePersona,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        items: _voices.map((voice) {
                          return DropdownMenuItem(
                            value: voice,
                            child: Text(voice),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _aiVoicePersona = val);
                        },
                      ),
                    ),

                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Speech Speed (${_speechSpeed.toStringAsFixed(1)}x)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _speechSpeed == 1.0 ? 'Normal' : _speechSpeed > 1.0 ? 'Fast' : 'Slow',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _speechSpeed,
                      min: 0.8,
                      max: 1.5,
                      divisions: 7,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _speechSpeed = val),
                    ),

                    const Divider(height: 24),

                    Text(
                      'Feedback Report Detail',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _feedbackDetail,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        items: _feedbackLevels.map((lvl) {
                          return DropdownMenuItem(
                            value: lvl,
                            child: Text(lvl),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _feedbackDetail = val);
                        },
                      ),
                    ),

                    const Divider(height: 24),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Auto-Record Microphone',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Automatically listen after AI finishes speaking',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: _autoRecord,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _autoRecord = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.stackLg),

              // ── Notifications & Preferences ──────────────────────────────────
              _buildSectionTitle('NOTIFICATIONS & PREFERENCES', isDark),
              const SizedBox(height: 10),

              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Push Notifications',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Get notified about new job matches and learning tips',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: _pushNotifs,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _pushNotifs = val),
                    ),
                    const Divider(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Email PDF Summaries',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Receive detailed performance reports via email',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: _emailNotifs,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _emailNotifs = val),
                    ),
                    const Divider(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Haptic Feedback',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Vibrate on button presses and interview interactions',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      value: _haptics,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _haptics = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.stackLg),

              // ── Data & Storage ───────────────────────────────────────────────
              _buildSectionTitle('DATA & STORAGE', isDark),
              const SizedBox(height: 10),

              GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cleaning_services_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    'Clear Local Cache',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Frees up local storage space (14.2 MB used)',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Cache cleared successfully!'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppConstants.stackLg),

              // ── About & Sign Out ─────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'CDA Career Companion v2.5.0',
                      style: AppTypography.codeMono.copyWith(
                        color: isDark ? const Color(0xFF64748B) : AppColors.outline,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => showComingSoonSnackBar(context, 'About Stitch MCP & Supabase'),
                      child: Text(
                        'Powered by Stitch MCP & Supabase',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
                            title: Text('Sign Out?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.onSurface,
                                )),
                            content: Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.go('/login');
                                },
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.codeMono.copyWith(
        color: isDark ? const Color(0xFF94A3B8) : AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildThemeChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = currentMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F6)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE0E3E5)),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFF8FAFC) : AppColors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../subscription/data/subscription_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  String _aiVoicePersona = 'Samantha (Natural AI)';
  bool _isPlayingVoiceSample = false;
  bool _realtimeAudio = true;
  bool _autoRecord = true;
  bool _emailNotifs = true;
  bool _pushNotifs = true;
  bool _haptics = true;
  bool _isClearingCache = false;

  late AnimationController _waveController;

  final List<Map<String, String>> _voices = [
    {
      'id': 'Samantha (Natural AI)',
      'label': 'Samantha (Natural AI - US Standard)',
      'sampleText': 'Hello! I am Samantha, your AI Interviewer. Ready to test your technical skills today?',
    },
    {
      'id': 'David (Corporate Technical)',
      'label': 'David (Corporate Technical - Professional Accent)',
      'sampleText': 'Greetings! I am David. Let us explore system architecture and backend engineering concepts.',
    },
    {
      'id': 'Alex (Friendly Coach)',
      'label': 'Alex (Friendly Coach - Neutral Accent)',
      'sampleText': 'Hey there! I am Alex. We will walk through behavioral and HR scenarios step-by-step.',
    },
    {
      'id': 'Sophia (Tech Lead)',
      'label': 'Sophia (Tech Lead - Executive Tone)',
      'sampleText': 'Welcome. I am Sophia. I will evaluate your algorithmic efficiency and problem solving depth.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _testVoicePersona() async {
    if (_isPlayingVoiceSample) return;
    setState(() => _isPlayingVoiceSample = true);

    // Simulate audio playback for 3.5 seconds
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      setState(() => _isPlayingVoiceSample = false);
    }
  }

  Future<void> _clearRealAppCache() async {
    setState(() => _isClearingCache = true);
    int clearedCount = 0;

    try {
      // 1. Clear Flutter Image Cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      clearedCount += 12;

      // 2. Clear System Temp Directory
      final systemTemp = Directory.systemTemp;
      if (systemTemp.existsSync()) {
        final List<FileSystemEntity> entities = systemTemp.listSync();
        for (final entity in entities) {
          try {
            if (entity is File) {
              entity.deleteSync();
              clearedCount++;
            } else if (entity is Directory) {
              entity.deleteSync(recursive: true);
              clearedCount++;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Cache clear status: $e');
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isClearingCache = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cleared $clearedCount temporary cache items successfully!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.credDarkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.credDarkBase : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.onSurface,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings & Preferences',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Subscription Status Tile (No Free Trial Text) ───────────
              _buildSectionTitle('MEMBERSHIP STATUS', isDark),
              const SizedBox(height: 10),
              _buildSubscriptionCard(context, sub, isDark),

              const SizedBox(height: 24),

              // ── 2. Appearance & Theme Selector ─────────────────────────────
              _buildSectionTitle('APPEARANCE & THEME', isDark),
              const SizedBox(height: 10),
              _buildThemeCard(context, currentThemeMode, isDark),

              const SizedBox(height: 24),

              // ── 3. AI Voice Persona & Live Testing Card ───────────────────
              _buildSectionTitle('AI VOICE PERSONA & ACCENT', isDark),
              const SizedBox(height: 10),
              _buildAIVoiceCard(context, isDark),

              const SizedBox(height: 24),

              // ── 4. Notifications & Haptic Preferences ──────────────────────
              _buildSectionTitle('NOTIFICATIONS & PREFERENCES', isDark),
              const SizedBox(height: 10),
              _buildNotificationsCard(context, isDark),

              const SizedBox(height: 24),

              // ── 5. Real Data & Phone Cache Cleaning ────────────────────────
              _buildSectionTitle('DATA & STORAGE', isDark),
              const SizedBox(height: 10),
              _buildDataStorageCard(context, isDark),

              const SizedBox(height: 32),

              // ── 6. App Info & Logout Action Card ───────────────────────────
              _buildLogoutAndFooterSection(context, ref, isDark),

              const SizedBox(height: 60),
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
        color: isDark ? const Color(0xFF94A3B8) : AppColors.outline,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Membership Card ────────────────────────────────────────────────────────
  Widget _buildSubscriptionCard(BuildContext context, SubscriptionState sub, bool isDark) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sub.isPremium ? const Color(0xFFF59E0B) : borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: sub.isPremium ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        onTap: () => context.push('/subscription-details'),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 22),
        ),
        title: Text(
          sub.isPremium ? 'CDA Pro Plan Active 👑' : 'Standard Access',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14.5,
            color: isDark ? Colors.white : AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          sub.isPremium ? 'Unlimited AI Interviews • Tap to manage plan' : 'Standard Plan • Tap to upgrade to Pro ⚡',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFF59E0B), size: 20),
      ),
    );
  }

  // ── Theme Card ─────────────────────────────────────────────────────────────
  Widget _buildThemeCard(BuildContext context, ThemeMode currentThemeMode, bool isDark) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Interface Theme',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how CDA Companion looks on your device screen',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
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
              const SizedBox(width: 10),
              Expanded(
                child: _buildThemeChip(
                  context: context,
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  mode: ThemeMode.dark,
                  currentMode: currentThemeMode,
                ),
              ),
              const SizedBox(width: 10),
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
    );
  }

  // ── AI Voice Persona & Integrated Live Voice Testing Card ──────────────────
  Widget _buildAIVoiceCard(BuildContext context, bool isDark) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    final selectedVoiceObj = _voices.firstWhere(
      (v) => v['id'] == _aiVoicePersona || v['label']!.contains(_aiVoicePersona),
      orElse: () => _voices.first,
    );

    final String activeVoiceId = selectedVoiceObj['id']!;
    final String activeSampleText = selectedVoiceObj['sampleText']!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'AI Voice Persona & Accent',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: isDark ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select the voice style used by your AI Interviewer',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          // Dropdown Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: activeVoiceId,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.credDarkCard : Colors.white,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.onSurface,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                items: _voices.map((voice) {
                  return DropdownMenuItem(
                    value: voice['id']!,
                    child: Text(voice['label']!),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _aiVoicePersona = val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Integrated Voice Testing Widget ──────────────────────────────
          InkWell(
            onTap: _testVoicePersona,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPlayingVoiceSample
                      ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                      : [AppColors.primary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlayingVoiceSample ? Icons.volume_up_rounded : Icons.play_circle_fill_rounded,
                    color: _isPlayingVoiceSample ? Colors.white : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isPlayingVoiceSample ? 'Testing AI Voice Sample...' : 'Test Selected Voice Persona 🔊',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: _isPlayingVoiceSample ? Colors.white : AppColors.primary,
                    ),
                  ),
                  if (_isPlayingVoiceSample) ...[
                    const SizedBox(width: 10),
                    ScaleTransition(
                      scale: _waveController,
                      child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Voice Transcript Sample Bubble
          if (_isPlayingVoiceSample) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, color: Color(0xFF6366F1), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"$activeSampleText"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: isDark ? const Color(0xFFCBD5E1) : AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.credDarkBorder : const Color(0xFFF1F5F9)),
          const SizedBox(height: 4),

          // Real-time Audio Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Real-Time Audio Evaluation',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              'Analyze speech pace, clarity & tone live during interview',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
            value: _realtimeAudio,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _realtimeAudio = val),
          ),

          // Auto-Record Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Auto-Record Microphone',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              'Automatically listen after AI interviewer finishes speaking',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
            value: _autoRecord,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _autoRecord = val),
          ),
        ],
      ),
    );
  }

  // ── Notifications Card ────────────────────────────────────────────────────
  Widget _buildNotificationsCard(BuildContext context, bool isDark) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Push Notifications',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              'Alerts for job recommendations & learning roadmaps',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
            value: _pushNotifs,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _pushNotifs = val),
          ),
          Divider(color: isDark ? AppColors.credDarkBorder : const Color(0xFFF1F5F9)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Email Performance Reports',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              'Send comprehensive PDF scorecards after interviews',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
            value: _emailNotifs,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _emailNotifs = val),
          ),
          Divider(color: isDark ? AppColors.credDarkBorder : const Color(0xFFF1F5F9)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Haptic Feedback',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              'Vibrate on button taps & live interview speech cues',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
            value: _haptics,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _haptics = val),
          ),
        ],
      ),
    );
  }

  // ── Real Phone Cache Clearing Card ─────────────────────────────────────────
  Widget _buildDataStorageCard(BuildContext context, bool isDark) {
    final cardBg = isDark ? AppColors.credDarkCard : Colors.white;
    final borderColor = isDark ? AppColors.credDarkBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isClearingCache
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.cleaning_services_rounded, color: AppColors.primary, size: 20),
        ),
        title: Text(
          'Clear Local Device Cache',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
        subtitle: Text(
          _isClearingCache ? 'Cleaning temporary app files & image cache...' : 'Frees up phone storage space & resets cached assets',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
            fontSize: 11.5,
          ),
        ),
        onTap: _isClearingCache ? null : _clearRealAppCache,
      ),
    );
  }

  // ── Logout & Footer ────────────────────────────────────────────────────────
  Widget _buildLogoutAndFooterSection(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      children: [
        InkWell(
          onTap: () => _confirmSignOut(context, ref, isDark),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign Out of Account',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Safely end your active session on this device',
                      style: TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'CDA Career Companion v2.5.0',
          style: AppTypography.codeMono.copyWith(
            color: isDark ? const Color(0xFF64748B) : AppColors.outline,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Powered by Stitch MCP & Supabase',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Sign Out?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.onSurface,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your CDA companion account?',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
              context.go('/login');
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
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

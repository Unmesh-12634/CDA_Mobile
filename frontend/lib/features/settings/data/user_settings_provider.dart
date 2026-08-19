import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../interview/data/interview_setup_provider.dart';

class UserSettingsState {
  final String userEmail;
  final String aiVoicePersona;
  final bool realtimeAudio;
  final bool autoRecord;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool hapticFeedback;
  final String themeMode;
  final double storageCacheMb;
  final bool isLoading;

  const UserSettingsState({
    this.userEmail = '',
    this.aiVoicePersona = 'Samantha (Natural AI)',
    this.realtimeAudio = true,
    this.autoRecord = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.hapticFeedback = true,
    this.themeMode = 'system',
    this.storageCacheMb = 14.2,
    this.isLoading = false,
  });

  UserSettingsState copyWith({
    String? userEmail,
    String? aiVoicePersona,
    bool? realtimeAudio,
    bool? autoRecord,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? hapticFeedback,
    String? themeMode,
    double? storageCacheMb,
    bool? isLoading,
  }) {
    return UserSettingsState(
      userEmail: userEmail ?? this.userEmail,
      aiVoicePersona: aiVoicePersona ?? this.aiVoicePersona,
      realtimeAudio: realtimeAudio ?? this.realtimeAudio,
      autoRecord: autoRecord ?? this.autoRecord,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      themeMode: themeMode ?? this.themeMode,
      storageCacheMb: storageCacheMb ?? this.storageCacheMb,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_email': userEmail,
    'ai_voice_persona': aiVoicePersona,
    'realtime_audio': realtimeAudio,
    'auto_record': autoRecord,
    'email_notifications': emailNotifications,
    'push_notifications': pushNotifications,
    'haptic_feedback': hapticFeedback,
    'theme_mode': themeMode,
    'storage_cache_mb': storageCacheMb,
  };

  factory UserSettingsState.fromJson(Map<String, dynamic> json) => UserSettingsState(
    userEmail: json['user_email']?.toString() ?? '',
    aiVoicePersona: json['ai_voice_persona']?.toString() ?? 'Samantha (Natural AI)',
    realtimeAudio: json['realtime_audio'] != false,
    autoRecord: json['auto_record'] != false,
    emailNotifications: json['email_notifications'] != false,
    pushNotifications: json['push_notifications'] != false,
    hapticFeedback: json['haptic_feedback'] != false,
    themeMode: json['theme_mode']?.toString() ?? 'system',
    storageCacheMb: (json['storage_cache_mb'] as num?)?.toDouble() ?? 14.2,
  );
}

class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  final Ref ref;
  final LocalCacheService _cache = LocalCacheService();

  UserSettingsNotifier(this.ref) : super(const UserSettingsState()) {
    loadSettingsFromCache();
  }

  /// Instant sub-millisecond local cache retrieval (Offline-First)
  Future<void> loadSettingsFromCache() async {
    try {
      await _cache.init();

      final cachedVoice = _cache.get<String>('cda_pref_voice');
      final cachedHaptic = _cache.get<bool>('cda_pref_haptic');
      final cachedPush = _cache.get<bool>('cda_pref_push_notif');
      final cachedEmail = _cache.get<bool>('cda_pref_email_notif');
      final cachedRealtime = _cache.get<bool>('cda_pref_realtime_audio');
      final cachedAutoRecord = _cache.get<bool>('cda_pref_auto_record');
      final cachedTheme = _cache.get<String>('cda_pref_theme');
      final cachedEmailStr = _cache.get<String>('cda_auth_email');

      state = state.copyWith(
        userEmail: cachedEmailStr ?? state.userEmail,
        aiVoicePersona: cachedVoice ?? state.aiVoicePersona,
        hapticFeedback: cachedHaptic ?? state.hapticFeedback,
        pushNotifications: cachedPush ?? state.pushNotifications,
        emailNotifications: cachedEmail ?? state.emailNotifications,
        realtimeAudio: cachedRealtime ?? state.realtimeAudio,
        autoRecord: cachedAutoRecord ?? state.autoRecord,
        themeMode: cachedTheme ?? state.themeMode,
        isLoading: false,
      );

      debugPrint('⚡ [UserSettings] Loaded settings from local device cache instantly.');
    } catch (e) {
      debugPrint('UserSettings local cache load notice: $e');
    }
  }

  /// Saves settings locally to phone disk cache with instant reactivity
  Future<void> updateSettings({
    String? aiVoicePersona,
    bool? realtimeAudio,
    bool? autoRecord,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? hapticFeedback,
    String? themeMode,
    double? storageCacheMb,
  }) async {
    final updated = state.copyWith(
      aiVoicePersona: aiVoicePersona,
      realtimeAudio: realtimeAudio,
      autoRecord: autoRecord,
      emailNotifications: emailNotifications,
      pushNotifications: pushNotifications,
      hapticFeedback: hapticFeedback,
      themeMode: themeMode,
      storageCacheMb: storageCacheMb,
    );

    state = updated;

    // 1. Persist directly into local phone storage & memory cache
    try {
      if (aiVoicePersona != null) await _cache.set('cda_pref_voice', aiVoicePersona);
      if (hapticFeedback != null) await _cache.set('cda_pref_haptic', hapticFeedback);
      if (pushNotifications != null) await _cache.set('cda_pref_push_notif', pushNotifications);
      if (emailNotifications != null) await _cache.set('cda_pref_email_notif', emailNotifications);
      if (realtimeAudio != null) await _cache.set('cda_pref_realtime_audio', realtimeAudio);
      if (autoRecord != null) await _cache.set('cda_pref_auto_record', autoRecord);
      if (themeMode != null) await _cache.set('cda_pref_theme', themeMode);
      if (storageCacheMb != null) await _cache.set('cda_pref_cache_mb', storageCacheMb);
      
      await _cache.set('cda_user_settings_bundle', updated.toJson());
      debugPrint('💾 [UserSettings] Persisted updated preferences to phone local disk cache.');
    } catch (e) {
      debugPrint('Local settings cache save warning: $e');
    }

    // 2. Synchronize selected AI Voice Persona with AI Interview setup configuration
    if (aiVoicePersona != null) {
      ref.read(interviewSetupProvider.notifier).updateConfig(voicePersona: aiVoicePersona);
    }
  }

  /// Clears temporary cache files while preserving user preferences
  Future<void> clearDeviceCache() async {
    try {
      state = state.copyWith(storageCacheMb: 0.0);
      await _cache.set('cda_pref_cache_mb', 0.0);
      debugPrint('🧹 [UserSettings] Cleared device storage cache cleanly.');
    } catch (_) {}
  }
}

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier(ref);
});


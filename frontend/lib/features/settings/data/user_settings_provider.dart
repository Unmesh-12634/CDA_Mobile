import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/network/java_api_service.dart';
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
    this.aiVoicePersona = 'christopher',
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
  };

  factory UserSettingsState.fromJson(Map<String, dynamic> json) => UserSettingsState(
    userEmail: json['user_email']?.toString() ?? '',
    aiVoicePersona: json['ai_voice_persona']?.toString() ?? 'christopher',
    realtimeAudio: json['realtime_audio'] == true,
    autoRecord: json['auto_record'] == true,
    emailNotifications: json['email_notifications'] != false,
    pushNotifications: json['push_notifications'] != false,
    hapticFeedback: json['haptic_feedback'] != false,
    themeMode: json['theme_mode']?.toString() ?? 'system',
    storageCacheMb: (json['storage_cache_mb'] as num?)?.toDouble() ?? 14.2,
  );
}


class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  final Ref ref;

  UserSettingsNotifier(this.ref) : super(const UserSettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    // 1. Instant load from local SharedPreferences disk
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        aiVoicePersona: prefs.getString('cda_pref_voice') ?? state.aiVoicePersona,
        hapticFeedback: prefs.getBool('cda_pref_haptic') ?? state.hapticFeedback,
        pushNotifications: prefs.getBool('cda_pref_push_notif') ?? state.pushNotifications,
        emailNotifications: prefs.getBool('cda_pref_email_notif') ?? state.emailNotifications,
        realtimeAudio: prefs.getBool('cda_pref_realtime_audio') ?? state.realtimeAudio,
        autoRecord: prefs.getBool('cda_pref_auto_record') ?? state.autoRecord,
        themeMode: prefs.getString('cda_pref_theme') ?? state.themeMode,
      );
    } catch (_) {}

    final user = SupabaseConfig.client.auth.currentUser;
    final email = user?.email ?? '';
    if (email.isEmpty) return;

    // 2. Try Java Enterprise Backend
    try {
      final javaSettings = await JavaApiService.fetchUserSettings(email: email);
      if (javaSettings != null) {
        state = UserSettingsState.fromJson(javaSettings).copyWith(isLoading: false);
        return;
      }
    } catch (_) {}

    // 3. Direct Supabase DB Fallback
    try {
      final res = await SupabaseConfig.client
          .from('user_settings')
          .select()
          .eq('user_email', email)
          .maybeSingle();

      if (res != null) {
        state = UserSettingsState.fromJson(res).copyWith(isLoading: false);
      }
    } catch (_) {}
  }

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

    // 1. Save to SharedPreferences for instant cold starts
    try {
      final prefs = await SharedPreferences.getInstance();
      if (aiVoicePersona != null) await prefs.setString('cda_pref_voice', aiVoicePersona);
      if (hapticFeedback != null) await prefs.setBool('cda_pref_haptic', hapticFeedback);
      if (pushNotifications != null) await prefs.setBool('cda_pref_push_notif', pushNotifications);
      if (emailNotifications != null) await prefs.setBool('cda_pref_email_notif', emailNotifications);
      if (realtimeAudio != null) await prefs.setBool('cda_pref_realtime_audio', realtimeAudio);
      if (autoRecord != null) await prefs.setBool('cda_pref_auto_record', autoRecord);
      if (themeMode != null) await prefs.setString('cda_pref_theme', themeMode);
    } catch (_) {}

    // 2. Synchronize selected AI Voice Persona with AI Interview setup configuration
    if (aiVoicePersona != null) {
      ref.read(interviewSetupProvider.notifier).updateConfig(voicePersona: aiVoicePersona);
    }


    final user = SupabaseConfig.client.auth.currentUser;
    final email = user?.email ?? '';
    if (email.isEmpty) return;
    final payload = updated.toJson()..['user_email'] = email;

    // 3. Save to Java Backend & Supabase DB
    JavaApiService.saveUserSettings(payload);
    try {
      await SupabaseConfig.client.from('user_settings').upsert(payload);
    } catch (_) {}
  }
}

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier(ref);
});


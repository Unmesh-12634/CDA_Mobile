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
    // 1. Instant local load from device disk (Phone storage)
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

    // 2. Cross-device Cloud Sync from Supabase
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final email = user?.email ?? '';
      if (email.isNotEmpty) {
        final res = await SupabaseConfig.client
            .from('user_settings')
            .select()
            .eq('user_email', email)
            .maybeSingle();

        if (res != null) {
          state = UserSettingsState.fromJson(res).copyWith(isLoading: false);
        }
      }
    } catch (e) {
      debugPrint('UserSettings cloud sync notice: $e');
    }
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

    // 1. Save directly into device phone storage (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (aiVoicePersona != null) await prefs.setString('cda_pref_voice', aiVoicePersona);
      if (hapticFeedback != null) await prefs.setBool('cda_pref_haptic', hapticFeedback);
      if (pushNotifications != null) await prefs.setBool('cda_pref_push_notif', pushNotifications);
      if (emailNotifications != null) await prefs.setBool('cda_pref_email_notif', emailNotifications);
      if (realtimeAudio != null) await prefs.setBool('cda_pref_realtime_audio', realtimeAudio);
      if (autoRecord != null) await prefs.setBool('cda_pref_auto_record', autoRecord);
      if (themeMode != null) await prefs.setString('cda_pref_theme', themeMode);
    } catch (e) {
      debugPrint('Local phone settings save notice: $e');
    }

    // 2. Synchronize selected AI Voice Persona with AI Interview setup configuration
    if (aiVoicePersona != null) {
      ref.read(interviewSetupProvider.notifier).updateConfig(voicePersona: aiVoicePersona);
    }

    // 3. Save to Supabase Cloud Tables (user_settings & user_interview_settings)
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final email = user?.email ?? state.userEmail;
      if (email.isNotEmpty) {
        final payload = updated.toJson()..['user_email'] = email;
        JavaApiService.saveUserSettings(payload);

        await SupabaseConfig.client.from('user_settings').upsert({
          'user_email': email,
          'push_notifications': updated.pushNotifications,
          'email_notifications': updated.emailNotifications,
          'haptic_feedback': updated.hapticFeedback,
          'theme_mode': updated.themeMode,
          'ai_voice_persona': updated.aiVoicePersona,
          'realtime_audio': updated.realtimeAudio,
          'auto_record': updated.autoRecord,
          'updated_at': DateTime.now().toIso8601String(),
        });

        await SupabaseConfig.client.from('user_interview_settings').upsert({
          'user_email': email,
          'interviewer_voice': updated.aiVoicePersona,
          'auto_submit_mic': updated.autoRecord,
          'show_live_transcript': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Cloud settings sync notice: $e');
    }
  }
}

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier(ref);
});


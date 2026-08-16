import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/network/java_api_service.dart';

class UserSettingsState {
  final String userEmail;
  final String aiVoicePersona;
  final bool realtimeAudio;
  final bool autoRecord;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool hapticFeedback;
  final String themeMode;
  final bool twoFactorEnabled;
  final double storageCacheMb;
  final bool isLoading;

  const UserSettingsState({
    this.userEmail = 'unii12634@gmail.com',
    this.aiVoicePersona = 'Samantha (Natural AI)',
    this.realtimeAudio = true,
    this.autoRecord = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.hapticFeedback = true,
    this.themeMode = 'system',
    this.twoFactorEnabled = false,
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
    bool? twoFactorEnabled,
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
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
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
    'two_factor_enabled': twoFactorEnabled,
  };

  factory UserSettingsState.fromJson(Map<String, dynamic> json) => UserSettingsState(
    userEmail: json['user_email']?.toString() ?? 'unii12634@gmail.com',
    aiVoicePersona: json['ai_voice_persona']?.toString() ?? 'Samantha (Natural AI)',
    realtimeAudio: json['realtime_audio'] == true,
    autoRecord: json['auto_record'] == true,
    emailNotifications: json['email_notifications'] != false,
    pushNotifications: json['push_notifications'] != false,
    hapticFeedback: json['haptic_feedback'] != false,
    themeMode: json['theme_mode']?.toString() ?? 'system',
    twoFactorEnabled: json['two_factor_enabled'] == true,
    storageCacheMb: (json['storage_cache_mb'] as num?)?.toDouble() ?? 14.2,
  );
}

class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  final Ref ref;

  UserSettingsNotifier(this.ref) : super(const UserSettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    final user = SupabaseConfig.client.auth.currentUser;
    final email = user?.email ?? 'unii12634@gmail.com';

    // 1. Try Java Enterprise Backend
    try {
      final javaSettings = await JavaApiService.fetchUserSettings(email: email);
      if (javaSettings != null) {
        state = UserSettingsState.fromJson(javaSettings).copyWith(isLoading: false);
        return;
      }
    } catch (_) {}

    // 2. Direct Supabase DB Fallback
    try {
      final res = await SupabaseConfig.client
          .from('user_settings')
          .select()
          .eq('user_email', email)
          .maybeSingle();

      if (res != null) {
        state = UserSettingsState.fromJson(res).copyWith(isLoading: false);
        return;
      }
    } catch (_) {}

    state = state.copyWith(isLoading: false);
  }

  Future<void> updateSettings({
    String? aiVoicePersona,
    bool? realtimeAudio,
    bool? autoRecord,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? hapticFeedback,
    String? themeMode,
    bool? twoFactorEnabled,
  }) async {
    final updated = state.copyWith(
      aiVoicePersona: aiVoicePersona ?? state.aiVoicePersona,
      realtimeAudio: realtimeAudio ?? state.realtimeAudio,
      autoRecord: autoRecord ?? state.autoRecord,
      emailNotifications: emailNotifications ?? state.emailNotifications,
      pushNotifications: pushNotifications ?? state.pushNotifications,
      hapticFeedback: hapticFeedback ?? state.hapticFeedback,
      themeMode: themeMode ?? state.themeMode,
      twoFactorEnabled: twoFactorEnabled ?? state.twoFactorEnabled,
    );

    state = updated;

    final user = SupabaseConfig.client.auth.currentUser;
    final email = user?.email ?? 'unii12634@gmail.com';
    final payload = updated.toJson()..['user_email'] = email;

    // 1. Save to Java Backend
    JavaApiService.saveUserSettings(payload);

    // 2. Save to Supabase DB
    try {
      await SupabaseConfig.client.from('user_settings').upsert(payload);
    } catch (_) {}
  }
}

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier(ref);
});

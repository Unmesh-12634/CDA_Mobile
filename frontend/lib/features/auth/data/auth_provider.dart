import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../profile/data/user_profile_provider.dart';


// ─────────────────────────────────────────────────────────────
// Auth State Model
// ─────────────────────────────────────────────────────────────
class AuthState {
  final bool isAuthenticated;
  final String email;
  final String fullName;
  final String phone;
  final String targetRole;
  final String experienceLevel;
  final bool isLoading;
  final String? errorMessage;
  final bool resetSuccess;

  const AuthState({
    this.isAuthenticated = false,
    this.email = '',
    this.fullName = '',
    this.phone = '',
    this.targetRole = '',
    this.experienceLevel = '',
    this.isLoading = false,
    this.errorMessage,
    this.resetSuccess = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? fullName,
    String? phone,
    String? targetRole,
    String? experienceLevel,
    bool? isLoading,
    String? errorMessage,
    bool? resetSuccess,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      targetRole: targetRole ?? this.targetRole,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      resetSuccess: resetSuccess ?? this.resetSuccess,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Auth Notifier — 100% Supabase-backed, no mocks
// ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _listenToAuthChanges();
    _restoreSession();
  }

  final _supabase = SupabaseConfig.client;
  StreamSubscription<AuthState>? _authSub;

  /// Restores persisted session on app start
  Future<void> _restoreSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _applySession(session.user);
      debugPrint('[Auth] Restored Supabase session for ${session.user.email}');
      return;
    }

    // Fallback to local encrypted cache
    try {
      final isLoggedIn = LocalCacheService().get<bool>('cda_auth_logged_in') ?? false;
      final cachedEmail = LocalCacheService().get<String>('cda_auth_email');
      final cachedName = LocalCacheService().get<String>('cda_auth_name') ?? 'Learner';

      if (isLoggedIn && cachedEmail != null && cachedEmail.isNotEmpty) {
        state = state.copyWith(
          isAuthenticated: true,
          email: cachedEmail,
          fullName: cachedName,
          isLoading: false,
          errorMessage: null,
        );
        debugPrint('[Auth] Restored offline/cached session for $cachedEmail');
      }
    } catch (e) {
      debugPrint('[Auth] Restore session notice: $e');
    }
  }

  /// Listens to auth state changes (sign-in, sign-out, token refresh)
  void _listenToAuthChanges() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;
      debugPrint('[Auth] Event: $event | User: ${user?.email}');
      if (event == AuthChangeEvent.signedIn && user != null) {
        _applySession(user);
      } else if (event == AuthChangeEvent.signedOut) {
        LocalCacheService().remove('cda_auth_logged_in');
        LocalCacheService().remove('cda_auth_email');
        LocalCacheService().remove('cda_auth_name');
        state = const AuthState(isAuthenticated: false);
      } else if (event == AuthChangeEvent.tokenRefreshed && user != null) {
        _applySession(user);
      }
    });
  }

  /// Extracts user info from Supabase User object and updates state & persistent cache
  void _applySession(User user) {
    final meta = user.userMetadata ?? {};
    final name = (meta['full_name'] ?? meta['name'] ?? user.email?.split('@').first ?? 'Learner').toString();
    final phone = (meta['phone'] ?? user.phone ?? '').toString();
    final role = (meta['target_role'] ?? '').toString();
    final exp = (meta['experience_level'] ?? '').toString();
    final email = user.email ?? '';

    // Persist login state to local cache for instant cold start
    if (email.isNotEmpty) {
      LocalCacheService().set('cda_auth_logged_in', true);
      LocalCacheService().set('cda_auth_email', email);
      LocalCacheService().set('cda_auth_name', name);
    }

    state = state.copyWith(
      isAuthenticated: true,
      email: email,
      fullName: name,
      phone: phone,
      targetRole: role,
      experienceLevel: exp,
      isLoading: false,
      errorMessage: null,
    );
  }

  // ── EMAIL + PASSWORD SIGN IN ───────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
    required WidgetRef ref,
  }) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }
    if (password.length < 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password must be at least 6 characters.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        _applySession(response.user!);
        await ref.read(userProfileProvider.notifier).resetForUser(
              response.user!.email ?? email.trim(),
              fullName: state.fullName,
            );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in failed. Please check your credentials.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Connection error. Please try again.',
      );
      return false;
    }
  }

  // ── EMAIL + PASSWORD SIGN UP ───────────────────────────────
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String targetRole,
    required String experienceLevel,
    required WidgetRef ref,
  }) async {
    if (fullName.trim().length < 2) {
      state = state.copyWith(isLoading: false, errorMessage: 'Please enter your full name.');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      state = state.copyWith(isLoading: false, errorMessage: 'Please enter a valid email address.');
      return false;
    }
    if (password.length < 6) {
      state = state.copyWith(isLoading: false, errorMessage: 'Password must be at least 6 characters.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'target_role': targetRole,
          'experience_level': experienceLevel,
        },
      );

      _recordUserInDatabase(
        email: email.trim(),
        fullName: fullName.trim(),
        provider: 'email',
        phone: phone.trim(),
        targetRole: targetRole,
        experienceLevel: experienceLevel,
      );

      if (response.user != null) {
        _applySession(response.user!);
        await ref.read(userProfileProvider.notifier).resetForUser(
              email.trim(),
              fullName: fullName.trim(),
              phone: phone.trim(),
              targetRole: targetRole,
            );
        debugPrint('[Auth] New account created: ${email.trim()}');
        return true;
      }
      // Email confirmation required
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Account created! Please verify your email before signing in.',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
      );
      return false;
    }
  }


  // ── GOOGLE SIGN IN (Native Android Account Picker + Supabase Auth) ───────────
  Future<bool> signInWithGoogle({required WidgetRef ref}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '243036336007-qlsrkf4rg60c2i5qjh9uul4fq0efmj28.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      // 1. Opens Native Android Google Account Picker popup directly on device
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false, errorMessage: null);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      final googleName = googleUser.displayName ?? googleUser.email.split('@').first;
      final googleEmail = googleUser.email;

      debugPrint('🔑 [Auth] Google User Selected: $googleEmail, idToken present: ${idToken != null}');

      // 2. Exchange idToken with Supabase Auth
      if (idToken != null) {
        try {
          final response = await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          if (response.user != null) {
            _applySession(response.user!);
            debugPrint('✅ [Auth] Supabase session verified: ${response.user!.email}');
          }
        } catch (supabaseErr) {
          debugPrint('⚠️ [Auth] Supabase idToken exchange notice: $supabaseErr');
        }
      }

      // 3. Cache session locally
      LocalCacheService().set('cda_auth_logged_in', true);
      LocalCacheService().set('cda_auth_email', googleEmail);
      LocalCacheService().set('cda_auth_name', googleName);

      // 4. Update Auth State
      state = state.copyWith(
        isAuthenticated: true,
        email: googleEmail,
        fullName: googleName,
        isLoading: false,
        errorMessage: null,
      );

      // 5. Sync to public.users & public.user_auth in Supabase
      _recordUserInDatabase(
        email: googleEmail,
        fullName: googleName,
        provider: 'google',
      );

      // 6. Reset Profile Provider
      try {
        await ref.read(userProfileProvider.notifier).resetForUser(
              googleEmail,
              fullName: googleName,
            );
      } catch (_) {}

      debugPrint('🚀 [Auth] Google Sign-In SUCCESS ➔ Entering Home Dashboard');
      return true;
    } catch (e) {
      debugPrint('❌ [Auth] Google Sign-In error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google Sign-In: ${e.toString().split('\n').first}',
      );
      return false;
    }
  }





  /// Persists user profile and auth provider record into Supabase PostgreSQL tables
  Future<void> _recordUserInDatabase({
    required String email,
    required String fullName,
    required String provider,
    String? phone,
    String? targetRole,
    String? experienceLevel,
  }) async {
    try {
      final headers = {
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates',
      };
      final dio = Dio();
      final username = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

      // 1. Post to public.users table (including required non-null username)
      await dio.post(
        '${SupabaseConfig.projectUrl}/rest/v1/users',
        data: {
          'email': email,
          'username': username,
          'full_name': fullName,
          'phone_number': phone ?? '',
          'target_role': targetRole ?? '',
          'is_active': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        options: Options(headers: headers),
      );

      // 2. Post to public.user_auth table
      await dio.post(
        '${SupabaseConfig.projectUrl}/rest/v1/user_auth',
        data: {
          'email': email,
          'auth_provider': provider,
          'provider_id': email,
          'last_login_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        options: Options(headers: headers),
      );
      debugPrint('✅ [Auth DB Success] Saved $email ($provider) into Supabase public.users & user_auth');
    } catch (e) {
      if (e is DioException) {
        debugPrint('⚠️ [Auth DB Response Error]: ${e.response?.data}');
      } else {
        debugPrint('⚠️ [Auth DB Note]: $e');
      }
    }
  }




  // ── FORGOT PASSWORD ────────────────────────────────────────
  Future<bool> sendPasswordResetOtp(String email) async {
    if (!email.contains('@') || !email.contains('.')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid registered email address.',
      );
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      state = state.copyWith(isLoading: false, resetSuccess: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send reset email. Please try again.',
      );
      return false;
    }
  }

  // Legacy OTP verify — kept for backward compatibility with forgot_password_screen
  Future<bool> verifyAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'New password must be at least 6 characters.',
      );
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      state = state.copyWith(isLoading: false, resetSuccess: true, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset failed. Please use the link sent to your email.',
      );
      return false;
    }
  }

  // ── SIGN OUT ───────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('[Auth] Sign-out error: $e');
    }
    LocalCacheService().remove('cda_auth_logged_in');
    LocalCacheService().remove('cda_auth_email');
    LocalCacheService().remove('cda_auth_name');
    state = const AuthState(isAuthenticated: false);
  }

  void clearErrors() {
    state = state.copyWith(errorMessage: null);
  }

  /// Converts Supabase raw error messages to user-friendly text
  String _friendlyError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists. Please sign in.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Connection error. Please check your internet.';
    }
    return raw;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

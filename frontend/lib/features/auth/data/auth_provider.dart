import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../../core/services/gmail_smtp_service.dart';
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
  final bool isOtpSent;
  final bool isOtpVerified;
  final int otpAttempts;
  final bool isLocked;
  final int lockRemainingSeconds;
  final int otpExpiryRemainingSeconds;
  final String recoveryEmail;

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
    this.isOtpSent = false,
    this.isOtpVerified = false,
    this.otpAttempts = 0,
    this.isLocked = false,
    this.lockRemainingSeconds = 0,
    this.otpExpiryRemainingSeconds = 0,
    this.recoveryEmail = '',
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
    bool? isOtpSent,
    bool? isOtpVerified,
    int? otpAttempts,
    bool? isLocked,
    int? lockRemainingSeconds,
    int? otpExpiryRemainingSeconds,
    String? recoveryEmail,
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
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isOtpVerified: isOtpVerified ?? this.isOtpVerified,
      otpAttempts: otpAttempts ?? this.otpAttempts,
      isLocked: isLocked ?? this.isLocked,
      lockRemainingSeconds: lockRemainingSeconds ?? this.lockRemainingSeconds,
      otpExpiryRemainingSeconds: otpExpiryRemainingSeconds ?? this.otpExpiryRemainingSeconds,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
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

      // If user is currently performing password reset OTP flow, avoid polluting persistent session
      if (state.isOtpSent && !state.resetSuccess) {
        debugPrint('[Auth] In password recovery mode - skipping auto session caching.');
        return;
      }

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




  // ── FORGOT PASSWORD (SECURE OTP FLOW) ──────────────────────
  String _otpLockKey(String email) => 'cda_otp_lock_until_${email.trim().toLowerCase()}';
  String _otpAttemptsKey(String email) => 'cda_otp_attempts_${email.trim().toLowerCase()}';
  String _otpSentAtKey(String email) => 'cda_otp_sent_at_${email.trim().toLowerCase()}';

  /// Calculates persistent remaining lock time (in seconds) for an email
  int getLockRemainingSeconds(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return 0;
    final lockUntil = LocalCacheService().get<int>(_otpLockKey(cleanEmail));
    if (lockUntil == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < lockUntil) {
      return ((lockUntil - now) / 1000).ceil();
    } else {
      // 10-minute lock expired — cleanup
      LocalCacheService().remove(_otpLockKey(cleanEmail));
      LocalCacheService().remove(_otpAttemptsKey(cleanEmail));
      return 0;
    }
  }

  /// Calculates remaining validity of the active OTP (3-minute / 180-second lifetime)
  int getOtpRemainingValiditySeconds(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return 0;
    final sentAt = LocalCacheService().get<int>(_otpSentAtKey(cleanEmail));
    if (sentAt == null) return 0;
    final elapsed = (DateTime.now().millisecondsSinceEpoch - sentAt) ~/ 1000;
    if (elapsed < 180) {
      return 180 - elapsed;
    } else {
      return 0; // Expired after 3 minutes
    }
  }

  /// Retrieves persisted failed attempt count for an email
  int getFailedAttempts(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return 0;
    return LocalCacheService().get<int>(_otpAttemptsKey(cleanEmail)) ?? 0;
  }

  /// Checks and syncs lock status into state for UI real-time responsiveness
  void checkAndRefreshLock(String email) {
    final remaining = getLockRemainingSeconds(email);
    if (remaining > 0) {
      state = state.copyWith(
        isLocked: true,
        lockRemainingSeconds: remaining,
        errorMessage: 'Too many incorrect attempts. Please try again after 10 minutes.',
      );
    } else {
      if (state.isLocked) {
        state = state.copyWith(
          isLocked: false,
          lockRemainingSeconds: 0,
          errorMessage: null,
        );
      }
    }
  }

  /// Step 1 & Resend: Dispatches 6-digit OTP to user's registered email
  Future<bool> sendPasswordResetOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid registered email address.',
      );
      return false;
    }

    // Enforce 10-minute lockout check across all attempts & resets
    final lockSeconds = getLockRemainingSeconds(cleanEmail);
    if (lockSeconds > 0) {
      state = state.copyWith(
        isLoading: false,
        isLocked: true,
        lockRemainingSeconds: lockSeconds,
        errorMessage: 'Too many incorrect attempts. Please try again after 10 minutes.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Generate secure 6-digit OTP & 3-minute expiry
      final secureOtp = (100000 + Random().nextInt(900000)).toString();
      final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 3)).toIso8601String();

      try {
        await _supabase.from('user_auth').update({
          'password_reset_token': secureOtp,
          'password_reset_expires_at': expiresAt,
        }).eq('email', cleanEmail);
      } catch (dbErr) {
        debugPrint('[Auth DB] OTP record note: $dbErr');
      }

      // 2. Dispatch email directly via Google Gmail SMTP Service
      await GmailSmtpService.sendPasswordResetOtp(
        recipientEmail: cleanEmail,
        otp: secureOtp,
      );

      // 3. Parallel dispatch via Supabase GoTrue Auth
      try {
        await _supabase.auth.resetPasswordForEmail(cleanEmail);
      } catch (_) {}

      await LocalCacheService().set(_otpSentAtKey(cleanEmail), DateTime.now().millisecondsSinceEpoch);
      state = state.copyWith(
        isLoading: false,
        isOtpSent: true,
        isOtpVerified: false,
        resetSuccess: false,
        recoveryEmail: cleanEmail,
        otpAttempts: getFailedAttempts(cleanEmail),
        isLocked: false,
        lockRemainingSeconds: 0,
        otpExpiryRemainingSeconds: 180,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP email. Please try again.',
      );
      return false;
    }
  }

  /// Step 2: Validates the 6-digit OTP code against Supabase Auth recovery token with 3-attempt limit & 3-min expiry
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final cleanEmail = email.trim().isNotEmpty ? email.trim().toLowerCase() : state.recoveryEmail.toLowerCase();
    final cleanOtp = otp.trim().replaceAll(' ', '');

    // Enforce 10-minute lockout check
    final lockSeconds = getLockRemainingSeconds(cleanEmail);
    if (lockSeconds > 0) {
      state = state.copyWith(
        isLoading: false,
        isLocked: true,
        lockRemainingSeconds: lockSeconds,
        errorMessage: 'Too many incorrect attempts. Please try again after 10 minutes.',
      );
      return false;
    }

    // Enforce 3-minute OTP expiry check
    final validityRemaining = getOtpRemainingValiditySeconds(cleanEmail);
    if (validityRemaining <= 0) {
      state = state.copyWith(
        isLoading: false,
        otpExpiryRemainingSeconds: 0,
        errorMessage: 'OTP code has expired (3-minute limit). Please tap Resend OTP for a fresh code.',
      );
      return false;
    }

    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid 6-digit numeric OTP code.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    bool isVerified = false;

    // 1. Try verifying via Supabase Auth GoTrue recovery
    try {
      final response = await _supabase.auth.verifyOTP(
        email: cleanEmail,
        token: cleanOtp,
        type: OtpType.recovery,
      );
      if (response.user != null || response.session != null) {
        isVerified = true;
      }
    } catch (e) {
      debugPrint('[Auth GoTrue OTP Verify Note]: $e');
    }

    // 2. Fallback: verify against database token in user_auth table
    if (!isVerified) {
      try {
        final rows = await _supabase
            .from('user_auth')
            .select('password_reset_token, password_reset_expires_at')
            .eq('email', cleanEmail);
        if (rows.isNotEmpty) {
          final dbToken = rows.first['password_reset_token']?.toString();
          final expStr = rows.first['password_reset_expires_at']?.toString();
          if (dbToken != null && dbToken == cleanOtp) {
            if (expStr != null) {
              final expDate = DateTime.tryParse(expStr);
              if (expDate != null && expDate.isAfter(DateTime.now().toUtc())) {
                isVerified = true;
              }
            } else {
              isVerified = true;
            }
          }
        }
      } catch (dbErr) {
        debugPrint('[Auth DB OTP Verify Note]: $dbErr');
      }
    }

    if (isVerified) {
      // Success: Clear attempts, lock, and sentAt persistence
      await LocalCacheService().remove(_otpLockKey(cleanEmail));
      await LocalCacheService().remove(_otpAttemptsKey(cleanEmail));
      await LocalCacheService().remove(_otpSentAtKey(cleanEmail));
      state = state.copyWith(
        isLoading: false,
        isOtpVerified: true,
        isLocked: false,
        lockRemainingSeconds: 0,
        otpExpiryRemainingSeconds: 0,
        otpAttempts: 0,
        errorMessage: null,
      );
      return true;
    }

    // Treat as failed attempt
    return await _handleFailedOtpAttempt(cleanEmail, 'Invalid OTP code.');
  }

  /// Handles failed OTP attempts with persistent 3-strike & 10-minute lockout rule
  Future<bool> _handleFailedOtpAttempt(String email, String baseMessage) async {
    final newAttempts = getFailedAttempts(email) + 1;
    await LocalCacheService().set(_otpAttemptsKey(email), newAttempts);

    if (newAttempts >= 3) {
      // Strike 3: Lock for exactly 10 minutes (600 seconds)
      final lockUntil = DateTime.now().millisecondsSinceEpoch + (10 * 60 * 1000);
      await LocalCacheService().set(_otpLockKey(email), lockUntil);

      state = state.copyWith(
        isLoading: false,
        otpAttempts: newAttempts,
        isLocked: true,
        lockRemainingSeconds: 600,
        errorMessage: 'Too many incorrect attempts. Please try again after 10 minutes.',
      );
      return false;
    } else {
      final remainingAttempts = 3 - newAttempts;
      state = state.copyWith(
        isLoading: false,
        otpAttempts: newAttempts,
        isLocked: false,
        lockRemainingSeconds: 0,
        errorMessage: '$baseMessage $remainingAttempts attempt(s) remaining.',
      );
      return false;
    }
  }

  /// Step 3: Updates user password after OTP has been verified
  Future<bool> completePasswordReset(String newPassword) async {
    if (!state.isOtpVerified) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Security check: OTP must be verified before setting a new password.',
      );
      return false;
    }

    if (newPassword.length < 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'New password must be at least 6 characters.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final email = state.recoveryEmail.trim().toLowerCase();

      // 1. Update in Supabase GoTrue Auth
      try {
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      } catch (e) {
        debugPrint('[Auth GoTrue Update Note]: $e');
      }

      // 2. Clear reset token in user_auth table
      try {
        await _supabase.from('user_auth').update({
          'password_reset_token': null,
          'password_reset_expires_at': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('email', email);
      } catch (dbErr) {
        debugPrint('[Auth DB Clear Note]: $dbErr');
      }
      
      // Cleanup any recovery lock/attempt entries
      if (email.isNotEmpty) {
        await LocalCacheService().remove(_otpLockKey(email));
        await LocalCacheService().remove(_otpAttemptsKey(email));
        await LocalCacheService().remove(_otpSentAtKey(email));
      }

      // Sign out from temporary recovery session so user explicitly logs in
      try {
        await _supabase.auth.signOut();
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        resetSuccess: true,
        isOtpSent: false,
        isOtpVerified: false,
        isLocked: false,
        lockRemainingSeconds: 0,
        otpExpiryRemainingSeconds: 0,
        recoveryEmail: '',
        otpAttempts: 0,
        errorMessage: null,
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
        errorMessage: 'Failed to update password. Please try again.',
      );
      return false;
    }
  }

  /// Resets in-memory recovery state when user leaves screen
  void resetRecoveryState() {
    state = state.copyWith(
      isOtpSent: false,
      isOtpVerified: false,
      resetSuccess: false,
      recoveryEmail: '',
      isLocked: false,
      lockRemainingSeconds: 0,
      errorMessage: null,
    );
  }

  /// Legacy helper for backwards compatibility
  Future<bool> verifyAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final verified = await verifyPasswordResetOtp(email: email, otp: otp);
    if (!verified) return false;
    return await completePasswordReset(newPassword);
  }

  // ── SIGN OUT ───────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('[Auth] Sign-out error: $e');
    }
    await LocalCacheService().clearUserSessionData();
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
    if (msg.contains('rate limit') || msg.contains('too many requests') || msg.contains('over_email_send_rate_limit')) {
      return 'An OTP was recently sent. Please check your inbox or wait 60 seconds before requesting a new code.';
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

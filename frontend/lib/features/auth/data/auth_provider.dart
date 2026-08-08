import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/user_profile_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final String email;
  final String fullName;
  final String phone;
  final String targetRole;
  final String experienceLevel;
  final bool isLoading;
  final String? errorMessage;
  final String? resetOtpSentTo;
  final bool resetSuccess;

  const AuthState({
    this.isAuthenticated = true, // Default to logged in for dev, updated on auth action
    this.email = 'alex.morgan@cda.ai',
    this.fullName = 'Arjun Verma',
    this.phone = '+91 98765 43210',
    this.targetRole = 'Senior AI & Full-Stack Engineer',
    this.experienceLevel = '1 - 3 Years',
    this.isLoading = false,
    this.errorMessage,
    this.resetOtpSentTo,
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
    String? resetOtpSentTo,
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
      resetOtpSentTo: resetOtpSentTo ?? this.resetOtpSentTo,
      resetSuccess: resetSuccess ?? this.resetSuccess,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  // ── SIGN IN ───────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
    required WidgetRef ref,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 900));

    if (email.trim().isEmpty || !email.contains('@')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid institute email address.',
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

    final name = email.split('@').first.replaceAll('.', ' ');
    final formattedName = name.isNotEmpty
        ? name[0].toUpperCase() + name.substring(1)
        : 'Student';

    // Update Profile Provider State
    ref.read(userProfileProvider.notifier).updateProfile(
          name: formattedName,
        );

    state = state.copyWith(
      isAuthenticated: true,
      email: email.trim(),
      fullName: formattedName,
      isLoading: false,
      errorMessage: null,
    );
    return true;
  }

  // ── SIGN UP ───────────────────────────────────────────────────
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String targetRole,
    required String experienceLevel,
    required WidgetRef ref,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 1100));

    if (fullName.trim().length < 2) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter your full name.',
      );
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    if (phone.trim().length < 8) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid 10-digit mobile number.',
      );
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password must be at least 6 characters long.',
      );
      return false;
    }

    // Sync to Profile Provider
    ref.read(userProfileProvider.notifier).updateProfile(
          name: fullName.trim(),
          targetRole: targetRole,
        );

    state = state.copyWith(
      isAuthenticated: true,
      email: email.trim(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      targetRole: targetRole,
      experienceLevel: experienceLevel,
      isLoading: false,
      errorMessage: null,
    );
    return true;
  }

  // ── FORGOT PASSWORD — STEP 1: SEND OTP ────────────────────────
  Future<bool> sendPasswordResetOtp(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null, resetSuccess: false);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!email.contains('@') || !email.contains('.')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid registered email address.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: false,
      resetOtpSentTo: email.trim(),
      errorMessage: null,
    );
    return true;
  }

  // ── FORGOT PASSWORD — STEP 2: VERIFY & RESET ──────────────────
  Future<bool> verifyAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (otp.length < 4) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter the complete OTP verification code.',
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

    state = state.copyWith(
      isLoading: false,
      resetSuccess: true,
      errorMessage: null,
    );
    return true;
  }

  // ── SIGN OUT ──────────────────────────────────────────────────
  void signOut() {
    state = const AuthState(isAuthenticated: false);
  }

  void clearErrors() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/network/java_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION STATE MODEL
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionState {
  final int trialsRemaining;
  final int totalFreeTrials;
  final bool isPremium;
  final String planName;
  final String billingCycle; // 'monthly' | 'yearly' | 'none'
  final DateTime? expiryDate;

  const SubscriptionState({
    this.trialsRemaining = 5,
    this.totalFreeTrials = 5,
    this.isPremium = false,
    this.planName = 'Standard Access',
    this.billingCycle = 'none',
    this.expiryDate,
  });

  SubscriptionState copyWith({
    int? trialsRemaining,
    int? totalFreeTrials,
    bool? isPremium,
    String? planName,
    String? billingCycle,
    DateTime? expiryDate,
  }) {
    return SubscriptionState(
      trialsRemaining: trialsRemaining ?? this.trialsRemaining,
      totalFreeTrials: totalFreeTrials ?? this.totalFreeTrials,
      isPremium: isPremium ?? this.isPremium,
      planName: planName ?? this.planName,
      billingCycle: billingCycle ?? this.billingCycle,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION NOTIFIER (Live Backend Integration)
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    loadLiveTrialsFromDb();
  }

  /// Loads real trial credits and PRO subscription state from Backend / DB
  Future<void> loadLiveTrialsFromDb({String? email}) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final targetEmail = email ?? user?.email ?? 'unii12634@gmail.com';

      // 1. Try Java Backend
      try {
        final javaSub = await JavaApiService.fetchSubscription(targetEmail);
        if (javaSub != null) {
          final remaining = javaSub['trialsRemaining'] as int? ?? 5;
          final total = javaSub['trialsTotal'] as int? ?? 5;
          final isPro = javaSub['pro'] as bool? ?? false;
          final plan = javaSub['planName'] as String? ?? (isPro ? 'CDA Pro Unlimited' : 'Standard Access');

          state = state.copyWith(
            trialsRemaining: remaining,
            totalFreeTrials: total,
            isPremium: isPro,
            planName: plan,
          );
          debugPrint('✅ Loaded live AI trials via Java Backend: $remaining/$total (Pro: $isPro)');
          return;
        }
      } catch (e) {
        debugPrint('Java backend subscription fetch notice: $e');
      }

      // 2. Direct Supabase DB Fallback
      final res = await SupabaseConfig.client
          .from('users')
          .select('ai_trials_remaining, ai_trials_total, is_pro_member')
          .eq('email', targetEmail)
          .maybeSingle();

      if (res != null) {
        final remaining = res['ai_trials_remaining'] as int? ?? 5;
        final total = res['ai_trials_total'] as int? ?? 5;
        final isPro = res['is_pro_member'] as bool? ?? false;

        state = state.copyWith(
          trialsRemaining: remaining,
          totalFreeTrials: total,
          isPremium: isPro,
          planName: isPro ? 'CDA Pro Unlimited' : 'Standard Access',
        );
        debugPrint('✅ Loaded live AI trials from Supabase DB: $remaining/$total (Pro: $isPro)');
      }
    } catch (e) {
      debugPrint('Error loading AI trials from DB: $e');
    }
  }

  /// Consumes 1 trial and decrements in Backend / DB
  Future<bool> consumeTrial() async {
    if (state.isPremium) return true;

    if (state.trialsRemaining <= 0) {
      return false; // Out of trials
    }

    final newRemaining = state.trialsRemaining - 1;
    state = state.copyWith(trialsRemaining: newRemaining);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final email = user?.email ?? 'unii12634@gmail.com';

      // Call Java backend
      JavaApiService.consumeTrial(email);

      await SupabaseConfig.client
          .from('users')
          .update({'ai_trials_remaining': newRemaining})
          .eq('email', email);

      debugPrint('✅ Decremented AI trial in DB! Remaining: $newRemaining');
    } catch (e) {
      debugPrint('Error updating AI trial in DB: $e');
    }
    return true;
  }

  /// Upgrades user to CDA Pro in Backend / DB
  Future<void> upgradeToPro({required String planId, required String billingCycle}) async {
    final now = DateTime.now();
    final expiry = billingCycle == 'yearly'
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);

    state = state.copyWith(
      isPremium: true,
      planName: 'CDA Pro Unlimited',
      billingCycle: billingCycle,
      expiryDate: expiry,
    );

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final email = user?.email ?? 'unii12634@gmail.com';

      // Call Java backend
      JavaApiService.upgradeToPro(email);

      await SupabaseConfig.client
          .from('users')
          .update({'is_pro_member': true})
          .eq('email', email);

      debugPrint('✅ Upgraded user to Pro in Backend/DB!');
    } catch (e) {
      debugPrint('Error saving Pro upgrade to DB: $e');
    }
  }

  /// Resets user state for testing
  Future<void> resetToStandard() async {
    state = const SubscriptionState(
      trialsRemaining: 5,
      totalFreeTrials: 5,
      isPremium: false,
      planName: 'Standard Access',
      billingCycle: 'none',
    );

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final email = user?.email ?? 'unii12634@gmail.com';

      await SupabaseConfig.client.from('users').update({
        'ai_trials_remaining': 5,
        'ai_trials_total': 5,
        'is_pro_member': false,
      }).eq('email', email);
    } catch (_) {}
  }

  void resetToFree() => resetToStandard();
}

// ─────────────────────────────────────────────────────────────────────────────
// RIVERPOD PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

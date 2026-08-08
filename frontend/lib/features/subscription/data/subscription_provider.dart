import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.trialsRemaining = 3,
    this.totalFreeTrials = 3,
    this.isPremium = false,
    this.planName = 'Free Tier',
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
// SUBSCRIPTION NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  /// Attempts to consume 1 free trial for an AI Mock Interview.
  /// Returns `true` if interview can proceed (either trial consumed or user is Premium).
  /// Returns `false` if user is out of free trials (triggers Paywall!).
  bool consumeTrial() {
    if (state.isPremium) {
      return true; // Unlimited interviews for Pro members
    }
    if (state.trialsRemaining > 0) {
      state = state.copyWith(trialsRemaining: state.trialsRemaining - 1);
      return true;
    }
    return false; // Out of trials!
  }

  /// Upgrades user to CDA Pro (INR pricing)
  void upgradeToPro({required String planId, required String billingCycle}) {
    final now = DateTime.now();
    final expiry = billingCycle == 'yearly'
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);

    state = state.copyWith(
      isPremium: true,
      trialsRemaining: 9999, // unlimited representation
      planName: 'CDA Pro Unlimited',
      billingCycle: billingCycle,
      expiryDate: expiry,
    );
  }

  /// Resets user state to Free Tier (3 trials) for testing
  void resetToFree() {
    state = const SubscriptionState(
      trialsRemaining: 3,
      totalFreeTrials: 3,
      isPremium: false,
      planName: 'Free Tier',
      billingCycle: 'none',
    );
  }

  /// Bonus trial awarded (e.g. from quiz or referral)
  void addBonusTrial() {
    if (!state.isPremium) {
      state = state.copyWith(trialsRemaining: state.trialsRemaining + 1);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIVERPOD PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

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
    this.trialsRemaining = 999,
    this.totalFreeTrials = 999,
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
// SUBSCRIPTION NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  bool consumeTrial() {
    return true; // Always allow interviews
  }

  void addBonusTrial() {}

  /// Upgrades user to CDA Pro (INR pricing)
  void upgradeToPro({required String planId, required String billingCycle}) {
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
  }

  /// Resets user state to Standard Access for testing
  void resetToStandard() {
    state = const SubscriptionState(
      isPremium: false,
      planName: 'Standard Access',
      billingCycle: 'none',
    );
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

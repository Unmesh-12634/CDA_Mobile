import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/network/java_api_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION STATE MODEL
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionState {
  final int trialsRemaining;
  final int totalFreeTrials;
  final bool isPremium;
  final String planName;
  final String billingCycle; // '1_hour' | '1_day' | '1_month' | '3_months' | '1_year' | 'none'
  final DateTime? startedDate;
  final DateTime? expiryDate;
  final int secondsRemaining;
  final int daysRemaining;
  final bool isExpired;

  const SubscriptionState({
    this.trialsRemaining = 5,
    this.totalFreeTrials = 5,
    this.isPremium = false,
    this.planName = 'Standard Access',
    this.billingCycle = 'none',
    this.startedDate,
    this.expiryDate,
    this.secondsRemaining = 0,
    this.daysRemaining = 0,
    this.isExpired = false,
  });

  SubscriptionState copyWith({
    int? trialsRemaining,
    int? totalFreeTrials,
    bool? isPremium,
    String? planName,
    String? billingCycle,
    DateTime? startedDate,
    DateTime? expiryDate,
    int? secondsRemaining,
    int? daysRemaining,
    bool? isExpired,
  }) {
    return SubscriptionState(
      trialsRemaining: trialsRemaining ?? this.trialsRemaining,
      totalFreeTrials: totalFreeTrials ?? this.totalFreeTrials,
      isPremium: isPremium ?? this.isPremium,
      planName: planName ?? this.planName,
      billingCycle: billingCycle ?? this.billingCycle,
      startedDate: startedDate ?? this.startedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION NOTIFIER (Live Backend + Database + Local Cache Integration)
// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    _restoreLocalState();
    loadLiveTrialsFromDb();
  }

  void _restoreLocalState() {
    try {
      final isPro = LocalCacheService().get<bool>('cda_pro_member') ?? false;
      final plan = LocalCacheService().get<String>('cda_pro_plan') ?? 'Standard Access';
      final expStr = LocalCacheService().get<String>('cda_pro_expires_at');
      final startStr = LocalCacheService().get<String>('cda_pro_started_at');

      DateTime? exp = expStr != null ? DateTime.tryParse(expStr) : null;
      DateTime? start = startStr != null ? DateTime.tryParse(startStr) : null;

      if (isPro && exp != null) {
        final now = DateTime.now();
        if (now.isAfter(exp)) {
          // Expired
          state = state.copyWith(isPremium: false, planName: 'Standard Access', isExpired: true);
        } else {
          final diff = exp.difference(now);
          state = state.copyWith(
            isPremium: true,
            planName: plan,
            expiryDate: exp,
            startedDate: start,
            secondsRemaining: diff.inSeconds,
            daysRemaining: diff.inDays,
            trialsRemaining: 9999,
          );
        }
      }
    } catch (_) {}
  }

  /// Loads real trial credits and PRO subscription state with strict timestamp verification
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
          final expireStr = javaSub['proExpiresAt']?.toString();
          final startStr = javaSub['proStartedAt']?.toString();
          final secRem = (javaSub['secondsRemaining'] as num?)?.toInt() ?? 0;
          final daysRem = (javaSub['daysRemaining'] as num?)?.toInt() ?? 0;
          final expired = javaSub['expired'] as bool? ?? false;

          DateTime? exp = expireStr != null ? DateTime.tryParse(expireStr) : null;
          DateTime? start = startStr != null ? DateTime.tryParse(startStr) : null;

          state = state.copyWith(
            trialsRemaining: remaining,
            totalFreeTrials: total,
            isPremium: isPro && !expired,
            planName: plan,
            expiryDate: exp,
            startedDate: start,
            secondsRemaining: secRem,
            daysRemaining: daysRem,
            isExpired: expired,
          );

          _saveLocalState(isPro: isPro && !expired, plan: plan, exp: exp, start: start);
          debugPrint('✅ Loaded live AI trials via Java Backend: $remaining/$total (Pro: $isPro, Exp: $exp)');
          return;
        }
      } catch (e) {
        debugPrint('Java backend subscription fetch notice: $e');
      }

      // 2. Direct Supabase DB Fallback
      final res = await SupabaseConfig.client
          .from('users')
          .select('ai_trials_remaining, ai_trials_total, is_pro_member, pro_plan, pro_started_at, pro_expires_at')
          .eq('email', targetEmail)
          .maybeSingle();

      if (res != null) {
        final remaining = res['ai_trials_remaining'] as int? ?? 5;
        final total = res['ai_trials_total'] as int? ?? 5;
        bool isPro = res['is_pro_member'] as bool? ?? false;
        String plan = res['pro_plan']?.toString() ?? (isPro ? 'CDA Pro Unlimited' : 'Standard Access');
        final expStr = res['pro_expires_at']?.toString();
        final startStr = res['pro_started_at']?.toString();

        DateTime? exp = expStr != null ? DateTime.tryParse(expStr) : null;
        DateTime? start = startStr != null ? DateTime.tryParse(startStr) : null;

        int secRem = 0;
        int daysRem = 0;
        bool expired = false;

        if (isPro && exp != null) {
          final now = DateTime.now();
          if (now.isAfter(exp)) {
            isPro = false;
            expired = true;
            plan = 'Standard Access';
            // Revert in DB
            _revertExpiredInDb(targetEmail);
          } else {
            final diff = exp.difference(now);
            secRem = diff.inSeconds;
            daysRem = diff.inDays;
          }
        }

        state = state.copyWith(
          trialsRemaining: isPro ? 9999 : remaining,
          totalFreeTrials: total,
          isPremium: isPro,
          planName: plan,
          expiryDate: exp,
          startedDate: start,
          secondsRemaining: secRem,
          daysRemaining: daysRem,
          isExpired: expired,
        );

        _saveLocalState(isPro: isPro, plan: plan, exp: exp, start: start);
        debugPrint('✅ Loaded live AI trials from Supabase DB: (Pro: $isPro, Exp: $exp)');
      }
    } catch (e) {
      debugPrint('Error loading AI trials from DB: $e');
    }
  }

  void _saveLocalState({required bool isPro, required String plan, DateTime? exp, DateTime? start}) {
    LocalCacheService().set('cda_pro_member', isPro);
    LocalCacheService().set('cda_pro_plan', plan);
    if (exp != null) LocalCacheService().set('cda_pro_expires_at', exp.toIso8601String());
    if (start != null) LocalCacheService().set('cda_pro_started_at', start.toIso8601String());
  }

  Future<void> _revertExpiredInDb(String email) async {
    try {
      try {
        NotificationService().showProExpiredNotification('CDA Pro Pass');
      } catch (_) {}

      await SupabaseConfig.client.from('users').update({
        'is_pro_member': false,
        'role': 'User',
        'pro_plan': 'Standard Access',
        'ai_trials_remaining': 5,
      }).eq('email', email);
    } catch (_) {}
  }

  /// Consumes 1 trial and decrements in Backend / DB
  Future<bool> consumeTrial() async {
    if (state.isPremium && !state.isExpired) return true;

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

  /// Upgrades user to CDA Pro with specific duration:
  /// '1_hour', '1_day', '1_month', '3_months', '1_year'
  Future<void> upgradeToPro({required String planId, required String billingCycle}) async {
    final now = DateTime.now();
    DateTime expiry;
    String planTitle;

    final cycle = billingCycle.toLowerCase().trim();
    if (cycle.contains('hour') || cycle == '1_hour') {
      expiry = now.add(const Duration(hours: 1));
      planTitle = 'CDA Pro (1-Hour Pass)';
    } else if (cycle.contains('day') || cycle == '1_day') {
      expiry = now.add(const Duration(days: 1));
      planTitle = 'CDA Pro (1-Day Pass)';
    } else if (cycle.contains('3_month') || cycle == 'quarterly') {
      expiry = DateTime(now.year, now.month + 3, now.day, now.hour, now.minute);
      planTitle = 'CDA Pro (3-Month Quarter)';
    } else if (cycle.contains('year') || cycle == 'yearly' || cycle == 'annual') {
      expiry = DateTime(now.year + 1, now.month, now.day, now.hour, now.minute);
      planTitle = 'CDA Pro (1-Year Annual)';
    } else {
      // Default 1 Month
      expiry = DateTime(now.year, now.month + 1, now.day, now.hour, now.minute);
      planTitle = 'CDA Pro (1-Month Monthly)';
    }

    final diff = expiry.difference(now);
    double amount = 499.0;
    if (cycle.contains('hour') || cycle == '1_hour') {
      amount = 9.0;
    } else if (cycle.contains('day') || cycle == '1_day') {
      amount = 49.0;
    } else if (cycle.contains('3_month') || cycle == 'quarterly') {
      amount = 1199.0;
    } else if (cycle.contains('year') || cycle == 'yearly' || cycle == 'annual') {
      amount = 2999.0;
    }

    state = state.copyWith(
      isPremium: true,
      planName: planTitle,
      billingCycle: cycle,
      startedDate: now,
      expiryDate: expiry,
      secondsRemaining: diff.inSeconds,
      daysRemaining: diff.inDays,
      trialsRemaining: 9999,
      isExpired: false,
    );

    _saveLocalState(isPro: true, plan: planTitle, exp: expiry, start: now);

    // 🔔 1. DISPATCH REAL MOBILE NOTIFICATION TO ANDROID NOTIFICATION CENTER
    try {
      await NotificationService().showProActivatedNotification(planTitle, expiry);
    } catch (e) {
      debugPrint('Notification dispatch notice: $e');
    }

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final cachedEmail = LocalCacheService().get<String>('cda_auth_email');
      final targetEmail = user?.email ?? cachedEmail ?? 'unii12634@gmail.com';

      // 2. Call Java backend
      JavaApiService.upgradeToPro(targetEmail, planCycle: cycle);

      // 3. Upsert public.users record
      await SupabaseConfig.client
          .from('users')
          .upsert({
            'email': targetEmail,
            'is_pro_member': true,
            'role': 'Pro',
            'pro_plan': planTitle,
            'pro_started_at': now.toIso8601String(),
            'pro_expires_at': expiry.toIso8601String(),
            'ai_trials_remaining': 9999,
            'updated_at': now.toIso8601String(),
          }, onConflict: 'email');

      // 4. Insert complete timeline record in public.user_subscriptions
      try {
        final subRes = await SupabaseConfig.client.from('user_subscriptions').insert({
          'user_email': targetEmail,
          'plan_name': planTitle,
          'billing_cycle': cycle,
          'amount_paid': amount,
          'currency': 'INR',
          'payment_method': 'UPI',
          'status': 'Active',
          'started_at': now.toIso8601String(),
          'expires_at': expiry.toIso8601String(),
          'created_at': now.toIso8601String(),
        }).select();
        debugPrint('✅ Inserted user_subscriptions row in Supabase: $subRes');
      } catch (subErr) {
        debugPrint('user_subscriptions table insert notice: $subErr');
      }

      // 5. Insert in-app notification record in public.notifications
      try {
        final formattedExp = '${expiry.day}/${expiry.month}/${expiry.year} ${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}';
        await SupabaseConfig.client.from('notifications').insert({
          'user_email': targetEmail,
          'title': '🎉 $planTitle Activated!',
          'body': 'Your CDA Pro pass is active from ${now.day}/${now.month}/${now.year} until $formattedExp. Unlimited AI mock interviews unlocked.',
          'type': 'subscription',
          'is_read': false,
          'created_at': now.toIso8601String(),
        });
      } catch (notifErr) {
        debugPrint('notifications table insert notice: $notifErr');
      }

      debugPrint('✅ Persisted complete subscription audit timeline for $targetEmail until $expiry!');
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
      isExpired: false,
    );

    _saveLocalState(isPro: false, plan: 'Standard Access', exp: null, start: null);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      final email = user?.email ?? 'unii12634@gmail.com';

      await SupabaseConfig.client.from('users').update({
        'ai_trials_remaining': 5,
        'ai_trials_total': 5,
        'is_pro_member': false,
        'role': 'User',
        'pro_plan': 'Standard Access',
        'pro_expires_at': null,
      }).eq('email', email);
    } catch (_) {}
  }

  void resetToFree() => resetToStandard();
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

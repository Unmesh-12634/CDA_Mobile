import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardTransaction {
  final String title;
  final int coins;
  final String timestamp;
  final bool isCredit;

  const RewardTransaction({
    required this.title,
    required this.coins,
    required this.timestamp,
    this.isCredit = true,
  });
}

class RewardsState {
  final int coinBalance;
  final int totalXp;
  final int level;
  final String levelTitle;
  final List<RewardTransaction> transactions;

  const RewardsState({
    this.coinBalance = 1250,
    this.totalXp = 3450,
    this.level = 4,
    this.levelTitle = 'Pro Scholar',
    this.transactions = const [
      RewardTransaction(title: 'Completed Daily Quiz', coins: 100, timestamp: '10 min ago'),
      RewardTransaction(title: '7-Day Streak Bonus', coins: 250, timestamp: 'Yesterday'),
      RewardTransaction(title: 'AI Interview Practice', coins: 200, timestamp: '2 days ago'),
      RewardTransaction(title: 'Profile Completion 88%', coins: 150, timestamp: '3 days ago'),
    ],
  });

  RewardsState copyWith({
    int? coinBalance,
    int? totalXp,
    int? level,
    String? levelTitle,
    List<RewardTransaction>? transactions,
  }) {
    return RewardsState(
      coinBalance: coinBalance ?? this.coinBalance,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      transactions: transactions ?? this.transactions,
    );
  }
}

class RewardsNotifier extends StateNotifier<RewardsState> {
  RewardsNotifier() : super(const RewardsState());

  void addCoins(int amount, String reason) {
    final newBalance = state.coinBalance + amount;
    final newXp = state.totalXp + (amount * 2);
    final updatedTx = [
      RewardTransaction(title: reason, coins: amount, timestamp: 'Just now'),
      ...state.transactions,
    ];

    state = state.copyWith(
      coinBalance: newBalance,
      totalXp: newXp,
      transactions: updatedTx,
    );
  }
}

final rewardsProvider = StateNotifierProvider<RewardsNotifier, RewardsState>((ref) {
  return RewardsNotifier();
});

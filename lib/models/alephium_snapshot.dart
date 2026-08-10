import '../utils/alephium_formats.dart';

class WalletSnapshot {
  const WalletSnapshot({
    required this.balance,
    required this.lockedBalance,
    required this.transactionCount,
    required this.fetchedAt,
  });

  final BigInt balance;
  final BigInt lockedBalance;
  final int transactionCount;
  final DateTime fetchedAt;

  factory WalletSnapshot.fromJson(Map<String, dynamic> json) {
    return WalletSnapshot(
      balance: attoToBigInt(json['balance']),
      lockedBalance: attoToBigInt(json['lockedBalance']),
      transactionCount: (json['txNumber'] is int)
          ? json['txNumber'] as int
          : int.tryParse(json['txNumber']?.toString() ?? '') ?? 0,
      fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance.toString(),
      'lockedBalance': lockedBalance.toString(),
      'txNumber': transactionCount,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }
}

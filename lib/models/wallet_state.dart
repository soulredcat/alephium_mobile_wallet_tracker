import 'alephium_snapshot.dart';
import 'alephium_transaction.dart';
import 'wallet_chart_point.dart';

class WalletAddressState {
  const WalletAddressState({
    this.snapshot,
    this.transactions = const [],
    this.chartPoints = const [],
    this.lastSyncAt,
    this.txPage = 1,
    this.hasMoreTx = true,
    this.isLoading = false,
    this.errorMessage,
  });

  final WalletSnapshot? snapshot;
  final List<AlephiumTransaction> transactions;
  final List<BalanceChartPoint> chartPoints;
  final DateTime? lastSyncAt;
  final int txPage;
  final bool hasMoreTx;
  final bool isLoading;
  final String? errorMessage;

  WalletAddressState copyWith({
    WalletSnapshot? snapshot,
    List<AlephiumTransaction>? transactions,
    List<BalanceChartPoint>? chartPoints,
    DateTime? lastSyncAt,
    int? txPage,
    bool? hasMoreTx,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WalletAddressState(
      snapshot: snapshot ?? this.snapshot,
      transactions: transactions ?? this.transactions,
      chartPoints: chartPoints ?? this.chartPoints,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      txPage: txPage ?? this.txPage,
      hasMoreTx: hasMoreTx ?? this.hasMoreTx,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'snapshot': snapshot?.toJson(),
      'transactions':
          transactions.map((item) => item.toJson()).toList(growable: false),
      'chartPoints': chartPoints
          .map(
            (point) => {
              'timestamp': point.timestamp.toIso8601String(),
              'balance': point.balance,
            },
          )
          .toList(growable: false),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'txPage': txPage,
      'hasMoreTx': hasMoreTx,
      'isLoading': isLoading,
      'errorMessage': errorMessage,
    };
  }

  factory WalletAddressState.fromJson(Map<String, dynamic> json) {
    final transactionJson =
        (json['transactions'] as List<dynamic>?) ?? const [];
    return WalletAddressState(
      snapshot: json['snapshot'] == null
          ? null
          : WalletSnapshot.fromJson(
              (json['snapshot'] as Map<String, dynamic>?) ?? const {},
            ),
      transactions: transactionJson
          .whereType<Map<String, dynamic>>()
          .map(AlephiumTransaction.fromCache)
          .toList(growable: false),
      chartPoints: ((json['chartPoints'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) {
        return BalanceChartPoint(
          timestamp: DateTime.tryParse(item['timestamp'] as String? ?? '') ??
              DateTime.now(),
          balance: (item['balance'] as num?)?.toDouble() ?? 0,
        );
      }).toList(growable: false),
      lastSyncAt: DateTime.tryParse(json['lastSyncAt'] as String? ?? ''),
      txPage: json['txPage'] is int ? json['txPage'] as int : 1,
      hasMoreTx: json['hasMoreTx'] as bool? ?? true,
      isLoading: json['isLoading'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

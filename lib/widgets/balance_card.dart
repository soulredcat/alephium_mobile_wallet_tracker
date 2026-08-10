import 'package:flutter/material.dart';

import '../models/alephium_snapshot.dart';
import '../utils/alephium_formats.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.snapshot, this.lastSyncAt, super.key});

  final WalletSnapshot? snapshot;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final snapshotMissing = snapshot == null;
    final balance =
        snapshotMissing ? 'Loading...' : formatAlph(snapshot!.balance);
    final locked = snapshotMissing ? '0' : formatAlph(snapshot!.lockedBalance);
    final available = snapshotMissing
        ? '-'
        : formatAlph(snapshot!.balance - snapshot!.lockedBalance);
    final txNumber = snapshot?.transactionCount.toString() ?? '-';
    final hasData = snapshot != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wallet balance',
                    style: theme.titleMedium,
                  ),
                ),
                if (snapshotMissing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$balance ALPH',
              style: theme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MetricPill(
                  label: 'Available',
                  value: available,
                  tone: hasData ? null : Colors.grey,
                ),
                const SizedBox(width: 8),
                _MetricPill(
                  label: 'Locked',
                  value: '$locked ALPH',
                  tone: Colors.orange,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction count: $txNumber'),
                if (!snapshotMissing) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.receipt_long, size: 16),
                ],
              ],
            ),
            if (lastSyncAt != null) ...[
              const SizedBox(height: 6),
              Text('Last updated: ${formatRelativeTime(lastSyncAt!)}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.tone,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color? tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chipColor = (tone ?? Colors.indigo).withValues(alpha: 0.08);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              compact ? value : '$value ALPH',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: tone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

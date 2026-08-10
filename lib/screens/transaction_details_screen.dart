import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/alephium_transaction.dart';
import '../theme/app_colors.dart';
import '../utils/alephium_formats.dart';
import '../widgets/explorer_card.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({required this.transaction, super.key});

  final AlephiumTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final incoming = transaction.isIncoming;
    final accent = incoming ? AppColors.positive : AppColors.negative;
    final amount = transaction.netAmount.abs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            tooltip: 'Copy transaction hash',
            onPressed: transaction.hash.isEmpty
                ? null
                : () => _copy(context, transaction.hash, 'Transaction hash copied'),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          ExplorerCard(
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    incoming ? Icons.south_rounded : Icons.north_east_rounded,
                    color: accent,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  incoming ? 'Received' : 'Sent',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${incoming ? '+' : '-'}${formatAlph(amount)} ALPH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (transaction.scriptOk ? AppColors.positive : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    transaction.scriptOk ? 'Confirmed' : 'Execution failed',
                    style: TextStyle(
                      color: transaction.scriptOk ? AppColors.positive : AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  formatUsdDate(transaction.timestamp),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ExplorerCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _DetailRow(
                  label: 'Transaction Hash',
                  value: transaction.hash.isEmpty ? '-' : transaction.hash,
                  monospace: true,
                  onCopy: transaction.hash.isEmpty
                      ? null
                      : () => _copy(context, transaction.hash, 'Transaction hash copied'),
                ),
                _DetailRow(
                  label: 'From',
                  value: transaction.fromAddress.isEmpty ? '-' : transaction.fromAddress,
                  monospace: true,
                  onCopy: transaction.fromAddress.isEmpty
                      ? null
                      : () => _copy(context, transaction.fromAddress, 'Sender address copied'),
                ),
                _DetailRow(
                  label: 'To',
                  value: transaction.toAddress.isEmpty ? '-' : transaction.toAddress,
                  monospace: true,
                  onCopy: transaction.toAddress.isEmpty
                      ? null
                      : () => _copy(context, transaction.toAddress, 'Recipient address copied'),
                ),
                _DetailRow(label: 'Net change', value: '${formatAlph(transaction.netAmount)} ALPH'),
                _DetailRow(label: 'Network fee', value: '${formatAlph(transaction.fee)} ALPH'),
                _DetailRow(
                  label: 'Block hash',
                  value: transaction.blockHash.isEmpty ? '-' : transaction.blockHash,
                  monospace: true,
                  onCopy: transaction.blockHash.isEmpty
                      ? null
                      : () => _copy(context, transaction.blockHash, 'Block hash copied'),
                ),
                _DetailRow(
                  label: 'Script execution',
                  value: transaction.scriptOk ? 'Success' : 'Failed',
                  valueColor: transaction.scriptOk ? AppColors.positive : AppColors.warning,
                ),
                _DetailRow(label: 'Coinbase', value: transaction.coinbase ? 'Yes' : 'No', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: transaction.hash.isEmpty
                ? null
                : () {
                    final url = 'https://explorer.alephium.org/transactions/${transaction.hash}';
                    _copy(context, url, 'Explorer URL copied');
                  },
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Copy Alephium Explorer URL'),
          ),
        ],
      ),
    );
  }

  static Future<void> _copy(BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.onCopy,
    this.valueColor,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool monospace;
  final VoidCallback? onCopy;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onCopy,
              child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

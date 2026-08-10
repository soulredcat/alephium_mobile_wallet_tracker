import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/alephium_transaction.dart';
import '../screens/transaction_details_screen.dart';
import '../utils/alephium_formats.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({required this.transaction, super.key});

  final AlephiumTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncoming = transaction.isIncoming;
    final sign = isIncoming ? '+' : '-';
    final amount = formatAlph(
      isIncoming ? transaction.incomingAmount : transaction.outgoingAmount,
    );
    final amountColor =
        isIncoming ? Colors.green.shade700 : Colors.red.shade700;
    final directionLabel =
        isIncoming ? 'Incoming transfer' : 'Outgoing transfer';
    final directionPrefix = isIncoming ? 'From' : 'To';
    final statusLabel = transaction.scriptOk ? 'Success' : 'Failed';
    final statusColor = transaction.scriptOk ? Colors.green : Colors.orange;
    final counterparty = _formatCounterpartyLine(isIncoming);
    final theme = Theme.of(context);
    final hashText = formatShortHex(transaction.hash);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openTransactionDetails(context),
      onLongPress: () => _copyToClipboard(
        context,
        transaction.hash,
        'Transaction hash copied',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hashText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 0.15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 15),
                  tooltip: 'Copy tx hash',
                  onPressed: () => _copyToClipboard(
                    context,
                    transaction.hash,
                    'Transaction hash copied',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: amountColor.withValues(alpha: 0.14),
                  foregroundColor: amountColor,
                  child: Icon(
                    isIncoming ? Icons.call_received : Icons.call_made,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$directionPrefix ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              counterparty,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (transaction.blockHash.isNotEmpty)
                        Text(
                          'Block ${formatShortHex(transaction.blockHash)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign$amount ALPH',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRelativeTime(transaction.timestamp),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sell_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Fee ${formatAlph(transaction.fee)} ALPH',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  isIncoming ? 'Inbound' : 'Outbound',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTransactionDetails(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransactionDetailsScreen(transaction: transaction),
      ),
    );
  }

  String _formatCounterpartyLine(bool isIncoming) {
    final from = transaction.fromAddress.isNotEmpty
        ? formatShortAddress(transaction.fromAddress)
        : null;
    final to = transaction.toAddress.isNotEmpty
        ? formatShortAddress(transaction.toAddress)
        : null;

    if (isIncoming) {
      return from ?? to ?? '-';
    }
    return to ?? from ?? '-';
  }

  void _copyToClipboard(
    BuildContext context,
    String value,
    String message,
  ) {
    if (value.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

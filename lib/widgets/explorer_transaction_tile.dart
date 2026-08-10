import 'package:flutter/material.dart';

import '../models/alephium_transaction.dart';
import '../theme/app_colors.dart';
import '../utils/alephium_formats.dart';

class ExplorerTransactionTile extends StatelessWidget {
  const ExplorerTransactionTile({
    required this.transaction,
    super.key,
    this.onTap,
  });

  final AlephiumTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final incoming = transaction.isIncoming;
    final directionColor = incoming ? AppColors.positive : AppColors.negative;
    final amount = incoming ? transaction.incomingAmount : transaction.netAmount.abs();
    final counterparty = incoming
        ? (transaction.fromAddress.isEmpty ? '-' : transaction.fromAddress)
        : (transaction.toAddress.isEmpty ? '-' : transaction.toAddress);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: directionColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
                    color: directionColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            incoming ? 'Received' : 'Sent',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: transaction.scriptOk
                                  ? AppColors.positive
                                  : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${incoming ? 'From' : 'To'}: ${formatShortAddress(counterparty)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${incoming ? '+' : '-'}${formatAlph(amount)} ALPH',
                      style: TextStyle(
                        color: directionColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRelativeTime(transaction.timestamp),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSoft),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hash: ${formatShortHex(transaction.hash)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  transaction.blockHash.isEmpty
                      ? 'Unconfirmed block'
                      : 'Block ${formatShortHex(transaction.blockHash, leadingChars: 6, trailingChars: 4)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

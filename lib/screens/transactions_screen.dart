import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alephium_transaction.dart';
import '../services/wallet_monitor_service.dart';
import '../theme/app_colors.dart';
import '../widgets/explorer_transaction_tile.dart';
import 'transaction_details_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  _DirectionFilter _filter = _DirectionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WalletMonitorService>();
    final state = service.selectedState;
    final transactions = _filteredTransactions(state?.transactions ?? const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: service.isNetworkAvailable && !service.isBusy
                ? () => service.refreshActiveAddress(force: true)
                : null,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => service.refreshActiveAddress(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by tx hash or address…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == _DirectionFilter.all,
                  onTap: () => setState(() => _filter = _DirectionFilter.all),
                ),
                _FilterChip(
                  label: 'Received',
                  selected: _filter == _DirectionFilter.received,
                  onTap: () => setState(() => _filter = _DirectionFilter.received),
                ),
                _FilterChip(
                  label: 'Sent',
                  selected: _filter == _DirectionFilter.sent,
                  onTap: () => setState(() => _filter = _DirectionFilter.sent),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (service.selectedAddress == null)
              const _EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No wallet selected',
                message: 'Add a wallet address from Overview to start exploring transactions.',
              )
            else if (state == null || state.transactions.isEmpty)
              const _EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No transactions yet',
                message: 'Refresh the selected address to synchronize its recent transaction history.',
              )
            else if (transactions.isEmpty)
              const _EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching transactions',
                message: 'Try a different search query or transaction direction filter.',
              )
            else ...[
              for (var i = 0; i < transactions.length; i++) ...[
                ExplorerTransactionTile(
                  transaction: transactions[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TransactionDetailsScreen(transaction: transactions[i]),
                    ),
                  ),
                ),
                if (i != transactions.length - 1) const SizedBox(height: 10),
              ],
              if (state?.hasMoreTx ?? false) ...[
                const SizedBox(height: 14),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: state?.isLoading == true || !service.isNetworkAvailable
                        ? null
                        : service.loadMoreTransactions,
                    icon: const Icon(Icons.expand_more_rounded),
                    label: const Text('Load more transactions'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<AlephiumTransaction> _filteredTransactions(List<AlephiumTransaction> input) {
    final query = _searchController.text.trim().toLowerCase();
    return input.where((tx) {
      final directionMatches = switch (_filter) {
        _DirectionFilter.all => true,
        _DirectionFilter.received => tx.isIncoming,
        _DirectionFilter.sent => !tx.isIncoming,
      };
      if (!directionMatches) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return tx.hash.toLowerCase().contains(query) ||
          tx.fromAddress.toLowerCase().contains(query) ||
          tx.toAddress.toLowerCase().contains(query) ||
          tx.blockHash.toLowerCase().contains(query);
    }).toList(growable: false);
  }
}

enum _DirectionFilter { all, received, sent }

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/alephium_address.dart';
import '../services/wallet_monitor_service.dart';
import '../theme/app_colors.dart';
import '../utils/alephium_formats.dart';
import '../widgets/explorer_balance_chart.dart';
import '../widgets/explorer_card.dart';
import '../widgets/explorer_transaction_tile.dart';
import 'transaction_details_screen.dart';

class AddressDetailsScreen extends StatelessWidget {
  const AddressDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WalletMonitorService>();
    final state = service.selectedState;
    final addressModel = _selectedModel(service);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Address Details'),
        actions: [
          IconButton(
            tooltip: 'Copy address',
            onPressed: service.selectedAddress == null
                ? null
                : () => _copy(context, service.selectedAddress!, 'Address copied'),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => service.refreshActiveAddress(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (addressModel == null)
              const _NoAddress()
            else ...[
              ExplorerCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primary, AppColors.info],
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF001E22)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        addressModel.label,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: service.isOnline ? AppColors.positive : AppColors.warning,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  formatShortAddress(addressModel.address),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.borderSoft),
                    GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: 2,
                      childAspectRatio: 1.95,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _Stat(label: 'Balance', value: '${formatAlph(state?.snapshot?.balance ?? BigInt.zero)} ALPH'),
                        _Stat(label: 'Locked', value: '${formatAlph(state?.snapshot?.lockedBalance ?? BigInt.zero)} ALPH'),
                        _Stat(label: 'Transactions', value: '${state?.snapshot?.transactionCount ?? 0}'),
                        _Stat(
                          label: 'Last sync',
                          value: state?.lastSyncAt == null ? 'Not synced' : formatRelativeTime(state!.lastSyncAt!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ExplorerCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Balance History',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text('Cached history', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ExplorerBalanceChart(points: state?.chartPoints ?? const []),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Tab(label: 'Transactions', selected: true),
                  const SizedBox(width: 8),
                  const _Tab(label: 'UTXOs', selected: false),
                  const SizedBox(width: 8),
                  const _Tab(label: 'Tokens', selected: false),
                ],
              ),
              const SizedBox(height: 12),
              if (state == null || state.transactions.isEmpty)
                const ExplorerCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('No recent transactions.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                )
              else
                for (var i = 0; i < state.transactions.take(6).length; i++) ...[
                  ExplorerTransactionTile(
                    transaction: state.transactions[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TransactionDetailsScreen(transaction: state.transactions[i]),
                      ),
                    ),
                  ),
                  if (i != state.transactions.take(6).length - 1) const SizedBox(height: 10),
                ],
            ],
          ],
        ),
      ),
    );
  }

  static AlephiumAddress? _selectedModel(WalletMonitorService service) {
    final selected = service.selectedAddress;
    if (selected == null) {
      return null;
    }
    for (final address in service.addresses) {
      if (address.address == selected) {
        return address;
      }
    }
    return null;
  }

  static Future<void> _copy(BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.borderSoft),
          bottom: BorderSide(color: AppColors.borderSoft),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NoAddress extends StatelessWidget {
  const _NoAddress();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.textMuted, size: 44),
          SizedBox(height: 14),
          Text('No wallet selected', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Add an Alephium address from Overview first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

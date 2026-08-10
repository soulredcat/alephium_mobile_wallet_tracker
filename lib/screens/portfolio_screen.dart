import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alephium_address.dart';
import '../services/wallet_monitor_service.dart';
import '../theme/app_colors.dart';
import '../utils/alephium_formats.dart';
import '../widgets/explorer_balance_chart.dart';
import '../widgets/explorer_card.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({required this.onOpenWallet, super.key});

  final Future<void> Function(String address) onOpenWallet;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WalletMonitorService>();
    final selectedState = service.selectedState;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            _LogoMark(),
            SizedBox(width: 10),
            Text('Alephium Explorer'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh selected wallet',
            onPressed: service.isNetworkAvailable &&
                    !service.isBusy &&
                    service.selectedAddress != null
                ? () => service.refreshActiveAddress(force: true)
                : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => service.refreshActiveAddress(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            ExplorerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total Portfolio Value',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                      Icon(
                        service.isOnline
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        size: 17,
                        color: service.isOnline
                            ? AppColors.positive
                            : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${formatAlph(service.totalBalance, decimals: 8)} ALPH',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MetricPill(
                        icon: Icons.lock_outline_rounded,
                        label:
                            '${formatAlph(service.totalLockedBalance)} locked',
                        color: AppColors.warning,
                      ),
                      _MetricPill(
                        icon: Icons.account_balance_wallet_outlined,
                        label:
                            '${service.addressCount} wallet${service.addressCount == 1 ? '' : 's'}',
                        color: AppColors.info,
                      ),
                    ],
                  ),
                  if (selectedState?.chartPoints.isNotEmpty ?? false) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 92,
                      child: ExplorerBalanceChart(
                          points: selectedState!.chartPoints),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Wallets',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddWallet(context),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Add Wallet'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (service.addresses.isEmpty)
              ExplorerCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 42, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No wallets tracked yet',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Add a public Alephium address. This app remains read-only and never asks for a seed or private key.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showAddWallet(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Track address'),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (var i = 0; i < service.addresses.length; i++) ...[
                _WalletCard(
                  address: service.addresses[i],
                  selected:
                      service.addresses[i].address == service.selectedAddress,
                  selectedBalance:
                      service.addresses[i].address == service.selectedAddress
                          ? selectedState?.snapshot?.balance
                          : null,
                  onTap: () => onOpenWallet(service.addresses[i].address),
                ),
                if (i != service.addresses.length - 1)
                  const SizedBox(height: 10),
              ],
            if (service.hasWarning || !service.isOnline) ...[
              const SizedBox(height: 16),
              ExplorerCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      service.isOnline
                          ? Icons.warning_amber_rounded
                          : Icons.cloud_off_rounded,
                      color: service.isOnline
                          ? AppColors.warning
                          : AppColors.negative,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        service.activeError ?? 'Some wallet data may be stale.',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> _showAddWallet(BuildContext context) async {
    final service = context.read<WalletMonitorService>();
    final result = await showModalBottomSheet<_PendingWallet?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundElevated,
      builder: (sheetContext) => _AddWalletSheet(
        onSubmit: (address, label) async {
          final normalized = address.trim();
          if (normalized.isEmpty) {
            return const _PendingWallet.error('Address is required');
          }
          if (!isValidAlephiumAddress(normalized)) {
            return const _PendingWallet.error('Invalid address');
          }
          return _PendingWallet(address: normalized, label: label);
        },
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    if (result.isError) {
      _showToast(context, result.message);
      return;
    }

    if (result.address == null || result.label == null) {
      if (!context.mounted) {
        return;
      }
      _showToast(context, 'Invalid address input');
      return;
    }

    try {
      await service.addAddress(
        result.address!,
        result.label!,
        refreshAfterAdd: false,
      );
      await Future<void>.delayed(Duration.zero);
      await service.refreshActiveAddress(force: true);
      if (!context.mounted) {
        return;
      }
      _showToast(context, 'Address added');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showToast(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  static void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AddWalletSheet extends StatefulWidget {
  const _AddWalletSheet({required this.onSubmit});

  final Future<_PendingWallet?> Function(String address, String label) onSubmit;

  @override
  State<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<_AddWalletSheet> {
  final _addressController = TextEditingController();
  final _labelController = TextEditingController();
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final normalizedAddress = _addressController.text.trim();
    final normalizedLabel = _labelController.text.trim();

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final result = await widget.onSubmit(normalizedAddress, normalizedLabel);
      if (!mounted) {
        return;
      }

      if (result != null && !result.isError) {
        Navigator.pop(context, result);
        return;
      }

      setState(() {
        _isSubmitting = false;
        _error = result?.message ?? 'Failed to add address';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Track Alephium Address',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Public address only. Never paste a private key or seed phrase.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _addressController,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: 'Alephium address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _labelController,
                decoration:
                    const InputDecoration(labelText: 'Wallet name (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: AppColors.negative, fontSize: 12),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add wallet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingWallet {
  const _PendingWallet({
    required this.address,
    required this.label,
    this.message = '',
    this.isError = false,
  });

  const _PendingWallet.error(String message)
      : this(
          address: null,
          label: null,
          message: message,
          isError: true,
        );

  final String? address;
  final String? label;
  final String message;
  final bool isError;
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.textPrimary, AppColors.primary],
        ),
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.w900,
              fontSize: 17),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.address,
    required this.selected,
    required this.onTap,
    this.selectedBalance,
  });

  final AlephiumAddress address;
  final bool selected;
  final BigInt? selectedBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ExplorerCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryMuted
                  : AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: selected ? AppColors.primary : AppColors.info,
            ),
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
                        address.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 7),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.positive, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  formatShortAddress(address.address),
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                      fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                selectedBalance == null
                    ? 'Open wallet'
                    : '${formatAlph(selectedBalance!, decimals: 6)} ALPH',
                style: TextStyle(
                  color: selectedBalance == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

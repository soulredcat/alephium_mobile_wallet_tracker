import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/alephium_address.dart';
import '../services/wallet_monitor_service.dart';
import '../utils/constants.dart';
import '../utils/alephium_formats.dart';
import '../models/alephium_transaction.dart';
import '../widgets/address_selector.dart';
import '../widgets/balance_card.dart';
import '../widgets/charts/balance_chart.dart';
import '../widgets/explorer_transaction_tile.dart';
import 'transaction_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _addressController = TextEditingController();
  final _labelController = TextEditingController();
  _TransactionFilter _transactionFilter = _TransactionFilter.all;
  _TransactionStatusFilter _statusFilter = _TransactionStatusFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletMonitorService>().initialize();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<WalletMonitorService>();
    final state = service.selectedState;
    final selectedAddress = service.selectedAddress;
    final selectedAddressModel =
        _getSelectedAddressModel(service, selectedAddress);
    final transactions = _filterTransactions(
      state?.transactions ?? const [],
      _transactionFilter,
      _statusFilter,
    );
    final canRefresh = service.isNetworkAvailable &&
        !service.isBusy &&
        selectedAddress != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alephium Wallet Monitor'),
            Text(
              service.isNetworkAvailable
                  ? (service.isOnline ? 'Sync active' : 'Sync partial')
                  : 'Waiting for connection',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Manage addresses',
            icon: const Icon(Icons.manage_accounts),
            onPressed: () => _openManageAddressesDialog(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              service.isNetworkAvailable
                  ? Icons.refresh
                  : Icons.wifi_off_outlined,
              color: canRefresh ? null : Colors.red,
            ),
            onPressed: canRefresh
                ? () => service.refreshActiveAddress(force: true)
                : null,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onPullToRefresh(service),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SyncStatusBanner(
              isOnline: service.isOnline,
              isWarning: service.hasWarning,
              message: service.activeError,
              canRetry: service.selectedAddress != null,
              onRetry: service.isNetworkAvailable
                  ? () => service.refreshActiveAddress(force: true)
                  : null,
            ),
            if (service.isBusy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _AddressSwitcherCard(
              addresses: service.addresses,
              selectedAddress: selectedAddress,
              onChanged: service.selectAddress,
              onAddAddress: () => _openAddAddressDialog(context),
            ),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Active address',
              action: service.isBusy
                  ? const Icon(Icons.sync, color: Colors.indigo, size: 16)
                  : null,
            ),
            if (selectedAddressModel != null)
              _SelectedAddressHeader(
                address: selectedAddressModel,
                onCopy: () => _copyToClipboard(
                  context,
                  selectedAddressModel.address,
                  'Selected address copied',
                ),
              ),
            const SizedBox(height: 12),
            if (service.addressCount > 1)
              _SummaryCard(
                title: 'All addresses total',
                totalBalance: service.totalBalance,
                totalLockedBalance: service.totalLockedBalance,
                lastSyncAt: state?.lastSyncAt,
              ),
            const SizedBox(height: 12),
            if (selectedAddress == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              BalanceCard(
                snapshot: state?.snapshot,
                lastSyncAt: state?.lastSyncAt,
              ),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Balance over time'),
              const SizedBox(height: 8),
              BalanceChartWidget(points: state?.chartPoints ?? const []),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Recent transactions'),
              const SizedBox(height: 8),
              if (state?.transactions.isNotEmpty ?? false) ...[
                _TransactionFilterBar(
                  filter: _transactionFilter,
                  statusFilter: _statusFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _transactionFilter = filter;
                    });
                  },
                  onStatusFilterChanged: (statusFilter) {
                    setState(() {
                      _statusFilter = statusFilter;
                    });
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (state == null || state.transactions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No transactions yet (try refreshing).'),
                  ),
                )
              else if (transactions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No transactions for this filter.'),
                  ),
                )
              else ...[
                if (state.errorMessage != null)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Data warning: ${state.errorMessage}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.25),
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length > maxDisplayedTransactions
                        ? maxDisplayedTransactions
                        : transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) => ExplorerTransactionTile(
                      transaction: transactions[index],
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => TransactionDetailsScreen(
                            transaction: transactions[index],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.hasMoreTx)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 4),
                      child: TextButton.icon(
                        onPressed: state.isLoading == true
                            ? null
                            : service.isNetworkAvailable
                                ? service.loadMoreTransactions
                                : null,
                        icon: Icon(
                          service.isNetworkAvailable
                              ? Icons.expand_more
                              : Icons.wifi_off,
                          size: 18,
                        ),
                        label: Text(
                          service.isNetworkAvailable ? 'Load more' : 'Offline',
                        ),
                      ),
                    ),
                  ),
              ],
              if (state?.isLoading ?? false)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
        onPressed: () => _openAddAddressDialog(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  AlephiumAddress? _getSelectedAddressModel(
    WalletMonitorService service,
    String? selectedAddress,
  ) {
    if (selectedAddress == null) {
      return null;
    }

    for (final item in service.addresses) {
      if (item.address == selectedAddress) {
        return item;
      }
    }

    return null;
  }

  Future<void> _openAddAddressDialog(BuildContext context) async {
    _addressController.clear();
    _labelController.clear();
    final service = context.read<WalletMonitorService>();

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _AddAddressSheet(
          addressController: _addressController,
          labelController: _labelController,
          onSubmit: (address, label) async {
            final normalized = address.trim();
            if (normalized.isEmpty) {
              return 'Address is required';
            }
            if (!isValidAlephiumAddress(normalized)) {
              return 'Invalid address';
            }

            try {
              await service.addAddress(normalized, label);
              return null;
            } catch (error) {
              return _extractErrorMessage(error);
            }
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }
    if (result.isNotEmpty) {
      _showToast(context, result);
      return;
    }
    _showToast(context, 'Address added');
  }

  Future<void> _openManageAddressesDialog(BuildContext context) async {
    final service = context.read<WalletMonitorService>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: AnimatedBuilder(
            animation: service,
            builder: (sheetContext, _) {
              final addresses = service.addresses;
              final insets = MediaQuery.of(sheetContext).viewInsets.bottom;

              if (addresses.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + insets,
                  ),
                  child: SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'No saved addresses.',
                        style: Theme.of(sheetContext).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + insets,
                ),
                child: SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage Addresses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: addresses.length,
                          separatorBuilder: (_, __) => const Divider(height: 0),
                          itemBuilder: (_, index) => _buildAddressManagerTile(
                            context: sheetContext,
                            service: service,
                            address: addresses[index],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddressManagerTile({
    required BuildContext context,
    required WalletMonitorService service,
    required AlephiumAddress address,
  }) {
    final isSelected = address.address == service.selectedAddress;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.star : Icons.account_balance_wallet_outlined,
        color: isSelected ? Colors.indigo : null,
      ),
      title: Text(address.label),
      subtitle: Text(formatShortAddress(address.address)),
      onTap: () async {
        if (address.address != service.selectedAddress) {
          await service.selectAddress(address.address);
        }
        if (!mounted) {
          return;
        }
        Navigator.pop(context);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit),
            onPressed: () => _renameAddress(context, service, address),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete),
            color: service.addressCount <= 1 ? Colors.grey : Colors.red,
            onPressed: service.addressCount <= 1
                ? null
                : () => _confirmDeleteAddress(context, service, address),
          ),
        ],
      ),
    );
  }

  Future<void> _renameAddress(
    BuildContext context,
    WalletMonitorService service,
    AlephiumAddress address,
  ) async {
    final controller = TextEditingController(text: address.label);
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: AnimatedPadding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rename address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Example: Main Wallet',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, controller.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();

    if (!mounted || result == null) {
      return;
    }
    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      _showToast(context, 'Name cannot be empty');
      return;
    }

    try {
      await service.renameAddress(address.address, trimmed);
      _showToast(context, 'Address name updated');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast(context, 'Failed to rename address');
    }
  }

  Future<void> _confirmDeleteAddress(
    BuildContext context,
    WalletMonitorService service,
    AlephiumAddress address,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete this address?'),
          content: Text(
            'Address ${address.label} will be removed from the list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await service.removeAddress(address.address);
      if (!mounted) {
        return;
      }
      _showToast(context, 'Address deleted');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast(context, 'Failed to delete address');
    }
  }

  String _extractErrorMessage(Object error) {
    final message = error.toString();
    if (message.isEmpty) {
      return 'Failed to process request';
    }
    return message.replaceFirst('Exception: ', '');
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onPullToRefresh(WalletMonitorService service) async {
    if (!service.isNetworkAvailable) {
      _showToast(context, 'No internet connection.');
      return;
    }
    await service.refreshActiveAddress(force: true);
  }

  List<AlephiumTransaction> _filterTransactions(
    List<AlephiumTransaction> transactions,
    _TransactionFilter filter,
    _TransactionStatusFilter statusFilter,
  ) {
    final directionFiltered = switch (filter) {
      _TransactionFilter.all => transactions,
      _TransactionFilter.incoming =>
        transactions.where((item) => item.isIncoming).toList(growable: false),
      _TransactionFilter.outgoing =>
        transactions.where((item) => !item.isIncoming).toList(growable: false),
    };

    return switch (statusFilter) {
      _TransactionStatusFilter.all => directionFiltered,
      _TransactionStatusFilter.failed => directionFiltered
          .where((item) => !item.scriptOk)
          .toList(growable: false),
      _TransactionStatusFilter.success => directionFiltered
          .where((item) => item.scriptOk)
          .toList(growable: false),
    };
  }
}

class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({
    required this.isOnline,
    required this.isWarning,
    this.message,
    this.canRetry = false,
    this.onRetry,
  });

  final bool isOnline;
  final bool isWarning;
  final String? message;
  final bool canRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (message == null || isOnline && !isWarning) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme;
    final statusColor = isOnline ? Colors.orange : Colors.red;
    final statusBg = isOnline
        ? Colors.orange.withValues(alpha: 0.08)
        : Colors.red.withValues(alpha: 0.08);
    final statusIcon = isOnline ? Icons.warning_amber : Icons.wifi_off;
    final statusTitle = isOnline ? 'Data warning' : 'Offline / not synced';

    if (!isOnline) {
      return Card(
        color: statusBg,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$statusTitle: $message',
                  style:
                      theme.bodyMedium?.copyWith(color: statusColor.shade900),
                ),
              ),
              if (canRetry && onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: statusBg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$statusTitle: $message',
                style: theme.bodyMedium?.copyWith(color: statusColor.shade900),
              ),
            ),
            if (canRetry && onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Refresh'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressSwitcherCard extends StatelessWidget {
  const _AddressSwitcherCard({
    required this.addresses,
    required this.selectedAddress,
    required this.onChanged,
    required this.onAddAddress,
  });

  final List<AlephiumAddress> addresses;
  final String? selectedAddress;
  final ValueChanged<String> onChanged;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: addresses.isEmpty
                  ? const Text('No addresses yet')
                  : Row(
                      children: [
                        Expanded(
                          child: AddressSelector(
                            addresses: addresses,
                            selectedAddress: selectedAddress,
                            onChanged: onChanged,
                          ),
                        ),
                        if (addresses.isNotEmpty) const SizedBox(width: 8),
                        if (addresses.isNotEmpty)
                          _PillChip(
                            label: _pluralizeAddressCount(addresses.length),
                          ),
                      ],
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add address',
              onPressed: onAddAddress,
            ),
          ],
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _pluralizeAddressCount(int count) {
  if (count == 1) {
    return '1 address';
  }
  return '$count addresses';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _TransactionFilterBar extends StatelessWidget {
  const _TransactionFilterBar({
    required this.filter,
    required this.statusFilter,
    required this.onFilterChanged,
    required this.onStatusFilterChanged,
  });

  final _TransactionFilter filter;
  final _TransactionStatusFilter statusFilter;
  final ValueChanged<_TransactionFilter> onFilterChanged;
  final ValueChanged<_TransactionStatusFilter> onStatusFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SegmentedButton<_TransactionFilter>(
          segments: const [
            ButtonSegment(
              value: _TransactionFilter.all,
              label: Text('All'),
            ),
            ButtonSegment(
              value: _TransactionFilter.incoming,
              label: Text('Incoming'),
            ),
            ButtonSegment(
              value: _TransactionFilter.outgoing,
              label: Text('Outgoing'),
            ),
          ],
          selected: {filter},
          onSelectionChanged: (values) {
            if (values.isEmpty) {
              return;
            }
            onFilterChanged(values.first);
          },
          showSelectedIcon: false,
        ),
        SegmentedButton<_TransactionStatusFilter>(
          segments: const [
            ButtonSegment(
              value: _TransactionStatusFilter.all,
              label: Text('All'),
            ),
            ButtonSegment(
              value: _TransactionStatusFilter.success,
              label: Text('Success'),
            ),
            ButtonSegment(
              value: _TransactionStatusFilter.failed,
              label: Text('Failed'),
            ),
          ],
          selected: {statusFilter},
          onSelectionChanged: (values) {
            if (values.isEmpty) {
              return;
            }
            onStatusFilterChanged(values.first);
          },
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

enum _TransactionFilter { all, incoming, outgoing }

enum _TransactionStatusFilter { all, success, failed }

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.totalBalance,
    required this.totalLockedBalance,
    this.lastSyncAt,
  });

  final String title;
  final BigInt totalBalance;
  final BigInt totalLockedBalance;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '${formatAlph(totalBalance)} ALPH',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Locked: ${formatAlph(totalLockedBalance)} ALPH',
              style: theme.textTheme.bodySmall,
            ),
            if (lastSyncAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last sync: ${formatRelativeTime(lastSyncAt!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedAddressHeader extends StatelessWidget {
  const _SelectedAddressHeader({
    required this.address,
    required this.onCopy,
  });

  final AlephiumAddress address;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.bookmark, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label,
                      style: theme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(formatShortAddress(address.address),
                        style: theme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy address',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: onCopy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _DashboardClipboard on _DashboardScreenState {
  Future<void> _copyToClipboard(
    BuildContext context,
    String value,
    String message,
  ) async {
    if (value.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet({
    required this.addressController,
    required this.labelController,
    required this.onSubmit,
  });

  final TextEditingController addressController;
  final TextEditingController labelController;
  final Future<String?> Function(String address, String label) onSubmit;

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  String? _errorMessage;
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    final address = widget.addressController.text.trim();
    final label = widget.labelController.text.trim();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final error = await widget.onSubmit(address, label);
      if (!mounted) {
        return;
      }

      if (error == null) {
        Navigator.pop(context, '');
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedPadding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Alephium Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  helperText: 'Example: 1Hkq...',
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.labelController,
                decoration: const InputDecoration(labelText: 'Name (optional)'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

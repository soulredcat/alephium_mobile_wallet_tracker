import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/alephium_address.dart';
import '../models/alephium_snapshot.dart';
import '../models/alephium_transaction.dart';
import '../models/wallet_chart_point.dart';
import '../models/wallet_state.dart';
import '../repository/alephium_api_repository.dart';
import '../repository/local_store_repository.dart';
import '../utils/constants.dart';
import '../utils/alephium_formats.dart';

class WalletMonitorService extends ChangeNotifier {
  static const _maxErrorLength = 140;

  WalletMonitorService({
    required AlephiumApiRepository apiRepository,
    required LocalStoreRepository localStoreRepository,
  })  : _apiRepository = apiRepository,
        _localStoreRepository = localStoreRepository;

  final AlephiumApiRepository _apiRepository;
  final LocalStoreRepository _localStoreRepository;

  final Map<String, WalletAddressState> _addressStates = {};
  final List<AlephiumAddress> _addresses = [];

  final _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySubscription;

  Timer? _refreshTimer;
  bool _initialized = false;
  _SyncStatus _syncStatus = _SyncStatus.unknown;
  bool _networkAvailable = true;
  String? _activeError;
  String? _connectivityErrorMessage;

  List<AlephiumAddress> get addresses => List.unmodifiable(_addresses);
  bool get isOnline => _syncStatus != _SyncStatus.offline;
  bool get hasWarning => _syncStatus == _SyncStatus.warning;
  bool get hasActiveState => selectedState != null;
  bool get hasAnyAddressData =>
      _addressStates.values.any((item) => item.snapshot != null);
  bool get isNetworkAvailable => _networkAvailable;
  String? get activeError => _activeError;
  bool get hasAddresses => _addresses.isNotEmpty;
  int get addressCount => _addresses.length;
  String? _selectedAddress;

  String? get selectedAddress => _selectedAddress;

  WalletAddressState? get selectedState =>
      _selectedAddress == null ? null : _addressStates[_selectedAddress];

  void _setSyncOnline() {
    _syncStatus = _SyncStatus.online;
    _activeError = null;
  }

  void _setSyncWarning(String message) {
    _syncStatus = _SyncStatus.warning;
    _activeError = _normalizeMessage(message);
  }

  void _setSyncOffline(String message) {
    _syncStatus = _SyncStatus.offline;
    _activeError = _normalizeMessage(message);
  }

  void _applySyncStateForSelection() {
    if (!_networkAvailable) {
      _setSyncOffline(_offlineMessage);
      return;
    }

    final stateError = selectedState?.errorMessage;
    if (stateError == null || stateError.isEmpty) {
      _setSyncOnline();
      return;
    }
    _setSyncWarning(stateError);
  }

  BigInt get totalBalance {
    return _addresses.fold(
      BigInt.zero,
      (total, address) =>
          total +
          (_addressStates[address.address]?.snapshot?.balance ?? BigInt.zero),
    );
  }

  BigInt get totalLockedBalance {
    return _addresses.fold(
      BigInt.zero,
      (total, address) =>
          total +
          (_addressStates[address.address]?.snapshot?.lockedBalance ??
              BigInt.zero),
    );
  }

  bool get isBusy {
    final selected = _selectedAddress;
    if (selected == null) {
      return false;
    }
    return _addressStates[selected]?.isLoading ?? false;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _loadPersistedState();

    _ensureSelectedAddress();
    if (_selectedAddress != null) {
      await _localStoreRepository.saveSelectedAddress(_selectedAddress!);
    }

    await _initializeConnectivity();
    _applySyncStateForSelection();
    await _refreshActiveAddress();
    _startRefreshTimer();
  }

  Future<void> _initializeConnectivity() async {
    final current = await _connectivity.checkConnectivity();
    _applyConnectivityResult(current);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (dynamic result) async {
        final wasOnline = _networkAvailable;
        _applyConnectivityResult(result);

        if (wasOnline == _networkAvailable) {
          return;
        }

        if (!_networkAvailable) {
          final message = _offlineMessage;
          _setSyncOffline(message);

          final address = _selectedAddress;
          if (address != null) {
            final currentState =
                _addressStates[address] ?? const WalletAddressState();
            _addressStates[address] = currentState.copyWith(
              isLoading: false,
              errorMessage: _normalizeMessage(message),
            );
          }
          notifyListeners();
          return;
        }

        _setSyncOnline();
        _applySyncStateForSelection();
        await _refreshActiveAddress(force: true);
      },
    );
  }

  bool _applyConnectivityResult(dynamic result) {
    final isConnected = _isConnectivityAvailable(result);
    _networkAvailable = isConnected;
    if (!_networkAvailable) {
      _connectivityErrorMessage = 'No internet connection.';
    } else {
      _connectivityErrorMessage = null;
    }
    return isConnected;
  }

  bool _isConnectivityAvailable(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }
    return true;
  }

  Future<void> _loadPersistedState() async {
    final persistedAddresses = await _localStoreRepository.loadAddresses();
    _addresses
      ..clear()
      ..addAll(persistedAddresses);

    if (persistedAddresses.isEmpty) {
      _addressStates.clear();
      return;
    }

    _selectedAddress = await _localStoreRepository.loadSelectedAddress();
    _addressStates.clear();

    for (final address in _addresses) {
      final state = await _localStoreRepository.loadState(address.address);
      if (state != null) {
        _addressStates[address.address] = state;
      } else {
        _addressStates[address.address] = const WalletAddressState();
      }
    }

    _ensureSelectedAddress();
    _applySyncStateForSelection();
    notifyListeners();
  }

  void _ensureSelectedAddress() {
    if (_addresses.isEmpty) {
      _selectedAddress = null;
      return;
    }

    final exists = _selectedAddress != null &&
        _addresses.any((item) => item.address == _selectedAddress);
    if (!exists) {
      _selectedAddress = _addresses.first.address;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(defaultRefreshInterval, (_) {
      _refreshActiveAddress();
    });
  }

  Future<void> selectAddress(String address) async {
    final exists = _addresses.any((item) => item.address == address);
    if (!exists) {
      return;
    }

    if (_selectedAddress == address) {
      return;
    }

    _selectedAddress = address;
    await _localStoreRepository.saveSelectedAddress(address);
    _applySyncStateForSelection();
    notifyListeners();
    await _refreshActiveAddress();
  }

  Future<void> addAddress(String address, String? label) async {
    final normalized = address.trim();
    if (!isValidAlephiumAddress(normalized)) {
      throw Exception('Invalid address');
    }

    final exists = _addresses.any((item) => item.address == normalized);
    if (exists) {
      throw Exception('Address already exists');
    }

    final newAddress = AlephiumAddress(
      address: normalized,
      label: (label == null || label.trim().isEmpty)
          ? formatShortAddress(normalized)
          : label.trim(),
      createdAt: DateTime.now(),
    );

    _addresses.add(newAddress);
    _addressStates[normalized] = const WalletAddressState();
    await _localStoreRepository.saveAddresses(_addresses);

    _selectedAddress = normalized;
    await _localStoreRepository.saveSelectedAddress(normalized);

    notifyListeners();
    await refreshActiveAddress(force: true);
  }

  Future<void> renameAddress(String address, String label) async {
    final index = _addresses.indexWhere((item) => item.address == address);
    if (index == -1) {
      throw Exception('Address not found');
    }

    final next = _addresses[index].copyWith(
      label: label.trim().isEmpty ? 'Default' : label.trim(),
    );
    _addresses[index] = next;
    await _localStoreRepository.saveAddresses(_addresses);
    notifyListeners();
  }

  Future<void> removeAddress(String address) async {
    final index = _addresses.indexWhere((item) => item.address == address);
    if (index == -1) {
      throw Exception('Address not found');
    }

    if (_addresses.length <= 1) {
      throw Exception('At least one address is required');
    }

    final removedSelected = _selectedAddress == address;
    _addresses.removeAt(index);
    _addressStates.remove(address);
    await _localStoreRepository.saveAddresses(_addresses);
    await _localStoreRepository.clearState(address);

    if (removedSelected) {
      _selectedAddress =
          _addresses.isNotEmpty ? _addresses.first.address : null;
      if (_selectedAddress == null) {
        throw Exception('Failed to select next address');
      }
      await _localStoreRepository.saveSelectedAddress(_selectedAddress!);
      _applySyncStateForSelection();
      notifyListeners();
      await refreshActiveAddress(force: true);
      return;
    }

    _ensureSelectedAddress();
    if (_selectedAddress != null) {
      await _localStoreRepository.saveSelectedAddress(_selectedAddress!);
    }
    _applySyncStateForSelection();
    notifyListeners();
  }

  Future<void> refreshActiveAddress({bool force = false}) async {
    await _refreshActiveAddress(force: force);
  }

  Future<void> _refreshActiveAddress({bool force = false}) async {
    final address = _selectedAddress;
    if (address == null) {
      return;
    }

    final existingState = _addressStates[address] ?? const WalletAddressState();
    if (!force && existingState.isLoading) {
      return;
    }

    if (!_networkAvailable) {
      final message = _offlineMessage;
      _addressStates[address] = existingState.copyWith(
        isLoading: false,
        errorMessage: _normalizeMessage(message),
      );
      _setSyncOffline(message);
      notifyListeners();
      return;
    }

    _addressStates[address] = existingState.copyWith(
      isLoading: true,
      clearError: true,
    );
    _activeError = null;
    notifyListeners();

    WalletSnapshot? summary;
    List<AlephiumTransaction> latestTransactions = const [];
    final hadCachedTransactions = existingState.transactions.isNotEmpty;

    try {
      summary = await _apiRepository.fetchAddressSummary(address);
    } catch (error) {
      final message = _humanizeError(error);
      _addressStates[address] = existingState.copyWith(
        isLoading: false,
        errorMessage: _normalizeMessage(message),
      );
      _setSyncOffline(message);
      notifyListeners();
      return;
    }

    var txFetchFailed = false;
    String txFetchError =
        'Balance updated, transaction history remains from cache.';
    try {
      latestTransactions = await _apiRepository.fetchAddressTransactions(
        address: address,
        page: 1,
      );
    } catch (error) {
      // Keep previous transaction history when pagination call fails.
      // Balance summary still updated so users still get balance updates.
      latestTransactions = existingState.transactions;
      txFetchFailed = true;
      txFetchError = _humanizeError(error);
      final warningMessage = txFetchError;
      _setSyncWarning(warningMessage);
    }

    final hasMoreTx = txFetchFailed
        ? existingState.hasMoreTx
        : latestTransactions.length == defaultTransactionPageSize;

    try {
      final mergedTransactions = _mergeTransactions(
        existingState.transactions,
        latestTransactions,
        baseLimit: maxCachedTransactionsPerAddress,
      );
      final nextTxPage = txFetchFailed ? existingState.txPage : 2;
      final chart = _buildBalanceChart(summary, mergedTransactions);

      final nextState = existingState.copyWith(
        snapshot: summary,
        transactions: mergedTransactions,
        chartPoints: chart,
        lastSyncAt: DateTime.now(),
        txPage: txFetchFailed ? nextTxPage : (hasMoreTx ? 2 : 1),
        hasMoreTx: hasMoreTx,
        isLoading: false,
        errorMessage: txFetchFailed
            ? _normalizeMessage(
                'Balance updated, transaction history remains from cache.',
              )
            : null,
      );

      _addressStates[address] = nextState;
      await _localStoreRepository.saveState(address, nextState);
      if (txFetchFailed) {
        final warningMessage = txFetchError;
        _setSyncWarning(warningMessage);
      } else {
        _setSyncOnline();
      }
    } catch (error) {
      final fallback = _addressStates[address] ?? const WalletAddressState();
      final message = _humanizeError(error);
      _addressStates[address] = fallback.copyWith(
        isLoading: false,
        errorMessage: _normalizeMessage(message),
      );
      if (hadCachedTransactions) {
        _setSyncWarning(message);
      } else {
        _setSyncOffline(message);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMoreTransactions() async {
    final address = _selectedAddress;
    if (address == null) {
      return;
    }

    final current = _addressStates[address] ?? const WalletAddressState();
    if (current.isLoading || !current.hasMoreTx) {
      return;
    }

    if (!_networkAvailable) {
      final message = _offlineMessage;
      _addressStates[address] = current.copyWith(
        isLoading: false,
        errorMessage: _normalizeMessage(message),
      );
      _setSyncOffline(message);
      notifyListeners();
      return;
    }

    _addressStates[address] = current.copyWith(
      isLoading: true,
      clearError: true,
    );
    _activeError = null;
    notifyListeners();

    final hadPartialData =
        current.transactions.isNotEmpty || current.snapshot != null;

    try {
      final nextPage = current.txPage < 1 ? 1 : current.txPage;
      final txs = await _apiRepository.fetchAddressTransactions(
        address: address,
        page: nextPage,
        limit: defaultTransactionPageSize,
      );
      final merged = _mergeTransactions(
        current.transactions,
        txs,
        baseLimit: maxCachedTransactionsPerAddress,
      );
      final summary = current.snapshot ??
          (await _apiRepository.fetchAddressSummary(address));
      final chart = _buildBalanceChart(summary, merged);
      final next = current.copyWith(
        transactions: merged,
        chartPoints: chart,
        txPage: nextPage + 1,
        hasMoreTx: txs.length == defaultTransactionPageSize,
        isLoading: false,
        lastSyncAt: DateTime.now(),
        clearError: true,
      );
      _addressStates[address] = next;
      await _localStoreRepository.saveState(address, next);
      _setSyncOnline();
    } catch (error) {
      final message = _humanizeError(error);
      _addressStates[address] = current.copyWith(
        isLoading: false,
        errorMessage: _normalizeMessage(message),
      );
      if (hadPartialData) {
        _setSyncWarning(message);
      } else {
        _setSyncOffline(message);
      }
    } finally {
      notifyListeners();
    }
  }

  String _humanizeError(Object error) {
    final message = error.toString();
    if (message.isEmpty) {
      return 'A connection or server failure occurred.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  String _normalizeMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return 'A connection or server failure occurred.';
    }
    if (trimmed.length <= _maxErrorLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, _maxErrorLength - 1)}…';
  }

  String get _offlineMessage {
    return _connectivityErrorMessage ?? 'No internet connection.';
  }

  List<AlephiumTransaction> _mergeTransactions(
    List<AlephiumTransaction> base,
    List<AlephiumTransaction> incoming, {
    int? baseLimit,
  }) {
    final limit = baseLimit ?? 200;
    final map = <String, AlephiumTransaction>{
      for (final item in base) item.hash: item,
    };
    for (final tx in incoming) {
      map[tx.hash] = tx;
    }

    final merged = map.values.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged.length <= limit ? merged : merged.sublist(0, limit);
  }

  List<BalanceChartPoint> _buildBalanceChart(
    WalletSnapshot snapshot,
    List<AlephiumTransaction> transactions,
  ) {
    if (transactions.isEmpty) {
      return [
        BalanceChartPoint(
          timestamp: snapshot.fetchedAt,
          balance: _toDoubleAlph(snapshot.balance),
        ),
      ];
    }

    BigInt runningBalance = snapshot.balance;
    final points = <BalanceChartPoint>[
      BalanceChartPoint(
        timestamp: snapshot.fetchedAt,
        balance: _toDoubleAlph(runningBalance),
      ),
    ];

    for (final tx in transactions) {
      runningBalance -= tx.netAmount;
      points.add(
        BalanceChartPoint(
          timestamp: tx.timestamp,
          balance: _toDoubleAlph(runningBalance),
        ),
      );
    }

    final ordered = points.reversed.toList(growable: false);
    ordered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return ordered;
  }

  double _toDoubleAlph(BigInt atto) {
    final unit = BigInt.from(10).pow(18);
    final absAtto = atto.abs();
    final whole = absAtto ~/ unit;
    final fraction = (absAtto % unit).toDouble() / unit.toDouble();
    final unsigned = whole.toDouble() + fraction;

    return atto.isNegative ? -unsigned : unsigned;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

enum _SyncStatus {
  online,
  warning,
  offline,
  unknown;
}

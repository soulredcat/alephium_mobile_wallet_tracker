import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alephium_address.dart';
import '../models/wallet_state.dart';
import '../utils/constants.dart';
import '../utils/alephium_formats.dart';

class LocalStoreRepository {
  LocalStoreRepository._(this._preferences);

  final SharedPreferences _preferences;

  static const _addressesKey = 'mobile_monitor.addresses.v1';
  static const _selectedAddressKey = 'mobile_monitor.selected_address.v1';
  static const _statePrefix = 'mobile_monitor.state.v1';

  static Future<LocalStoreRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalStoreRepository._(preferences);
  }

  String _stateKey(String address) {
    return '$_statePrefix.${base64Url.encode(utf8.encode(address))}';
  }

  Future<List<AlephiumAddress>> loadAddresses() async {
    final raw = _preferences.getString(_addressesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      await _preferences.remove(_addressesKey);
      return [];
    }
    if (decoded is! List<dynamic>) {
      await _preferences.remove(_addressesKey);
      return [];
    }

    final addresses = decoded
        .whereType<Map<String, dynamic>>()
        .map(AlephiumAddress.fromJson)
        .where((item) => isValidAlephiumAddress(item.address))
        .toList(growable: false);

    final unique = <String, AlephiumAddress>{};
    for (final item in addresses) {
      unique[item.address] = item;
    }

    final ordered = unique.values.toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ordered;
  }

  Future<void> saveAddresses(List<AlephiumAddress> addresses) async {
    final payload = addresses.map((item) => item.toJson()).toList();
    await _preferences.setString(_addressesKey, jsonEncode(payload));
  }

  Future<String?> loadSelectedAddress() async {
    return _preferences.getString(_selectedAddressKey);
  }

  Future<void> saveSelectedAddress(String address) async {
    await _preferences.setString(_selectedAddressKey, address);
  }

  Future<WalletAddressState?> loadState(String address) async {
    final raw = _preferences.getString(_stateKey(address));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      await _preferences.remove(_stateKey(address));
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      await _preferences.remove(_stateKey(address));
      return null;
    }

    try {
      return WalletAddressState.fromJson(decoded);
    } catch (_) {
      await _preferences.remove(_stateKey(address));
      return null;
    }
  }

  Future<void> saveState(String address, WalletAddressState state) async {
    await _preferences.setString(
      _stateKey(address),
      jsonEncode(state.toJson()),
    );
  }

  Future<void> saveDefaultDataIfMissing() async {
    final addresses = await loadAddresses();
    final hasDefault = addresses.any(
      (item) => item.address == defaultAlephiumAddress,
    );

    if (hasDefault) {
      return;
    }

    final defaultAddress = AlephiumAddress(
      address: defaultAlephiumAddress,
      label: 'Default',
      createdAt: DateTime.now(),
      isDefault: true,
    );
    await saveAddresses([defaultAddress]);
    await saveSelectedAddress(defaultAlephiumAddress);
  }

  Future<void> clearState(String address) async {
    await _preferences.remove(_stateKey(address));
  }
}

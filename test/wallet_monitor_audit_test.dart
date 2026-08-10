import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobilemonitor/models/alephium_snapshot.dart';
import 'package:mobilemonitor/models/alephium_transaction.dart';
import 'package:mobilemonitor/repository/alephium_api_repository.dart';
import 'package:mobilemonitor/repository/local_store_repository.dart';
import 'package:mobilemonitor/screens/portfolio_screen.dart';
import 'package:mobilemonitor/services/wallet_monitor_service.dart';

const _sampleAddress =
    '1HkqAaFZYDh2r9K67JoSiwf4ph7f2qZU1trBDu9nC2C3U';

class _StableApiRepository extends AlephiumApiRepository {
  _StableApiRepository() : super(baseUrl: 'https://example.invalid');

  @override
  Future<WalletSnapshot> fetchAddressSummary(String address) async {
    return WalletSnapshot(
      balance: BigInt.from(1200) * BigInt.from(10).pow(15),
      lockedBalance: BigInt.zero,
      transactionCount: 0,
      fetchedAt: DateTime.parse('2026-01-01T00:00:00Z'),
    );
  }

  @override
  Future<List<AlephiumTransaction>> fetchAddressTransactions({
    required String address,
    int page = 1,
    int limit = 30,
  }) {
    return Future.value(const []);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy default address is removed when loading persisted addresses', () async {
    SharedPreferences.setMockInitialValues({
      'mobile_monitor.addresses.v1': jsonEncode([
        {
          'address': _sampleAddress,
          'label': 'Legacy default',
          'createdAt': DateTime(2024).toIso8601String(),
          'isDefault': true,
        },
      ]),
      'mobile_monitor.selected_address.v1': _sampleAddress,
    });

    final repository = await LocalStoreRepository.create();

    final addresses = await repository.loadAddresses();
    final selectedAddress = await repository.loadSelectedAddress();

    expect(addresses, isEmpty);
    expect(selectedAddress, isNull);
  });

  testWidgets(
    'adding a wallet from portfolio screen does not throw framework exceptions',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repository = await LocalStoreRepository.create();
      final service = WalletMonitorService(
        apiRepository: _StableApiRepository(),
        localStoreRepository: repository,
      );
      addTearDown(service.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<WalletMonitorService>.value(
          value: service,
          child: const MaterialApp(
            home: PortfolioScreen(onOpenWallet: _fakeOpenWallet),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No wallets tracked yet'), findsOneWidget);
      await tester.tap(find.text('Track address'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Alephium address'),
        _sampleAddress,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Wallet name (optional)'),
        'Testing Wallet',
      );
      await tester.tap(find.text('Add wallet'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(service.addresses, isNotEmpty);
      expect(service.addresses.first.address, _sampleAddress);
      expect(find.text('Testing Wallet'), findsOneWidget);
    },
  );
}

Future<void> _fakeOpenWallet(String address) async {
  return;
}

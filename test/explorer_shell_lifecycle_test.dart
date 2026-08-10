import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobilemonitor/main.dart';
import 'package:mobilemonitor/repository/alephium_api_repository.dart';
import 'package:mobilemonitor/repository/local_store_repository.dart';
import 'package:mobilemonitor/services/wallet_monitor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('explorer shell mounts, switches tabs, and deactivates cleanly',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storeRepository = await LocalStoreRepository.create();
    final service = WalletMonitorService(
      apiRepository: AlephiumApiRepository(
        baseUrl: 'https://example.invalid',
      ),
      localStoreRepository: storeRepository,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<WalletMonitorService>.value(
        value: service,
        child: const MobileMonitorApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Alephium Explorer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Wallets'));
    await tester.pumpAndSettle();
    expect(find.text('Address Details'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Transactions').last);
    await tester.pumpAndSettle();
    expect(find.text('No wallet selected'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Monitor mode'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    service.dispose();
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repository/alephium_api_repository.dart';
import 'repository/local_store_repository.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'services/wallet_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiRepository = AlephiumApiRepository();
  final storeRepository = await LocalStoreRepository.create();

  runApp(
    ChangeNotifierProvider(
      create: (_) => WalletMonitorService(
        apiRepository: apiRepository,
        localStoreRepository: storeRepository,
      ),
      child: const MobileMonitorApp(),
    ),
  );
}

class MobileMonitorApp extends StatelessWidget {
  const MobileMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alephium Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'state/ble/ble_manager_provider.dart';
import 'state/connection/connection_provider.dart';
import 'state/device/device_provider.dart';
import 'state/telemetry/telemetry_provider.dart';
import 'state/theme/theme_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProxyProvider2<
          DeviceProvider,
          ConnectionProvider,
          BleManagerProvider
        >(
          create: (_) => BleManagerProvider(),
          update: (_, deviceProvider, connectionProvider, bleProvider) {
            bleProvider ??= BleManagerProvider();
            bleProvider.initialize(
              deviceProvider: deviceProvider,
              connectionProvider: connectionProvider,
            );
            return bleProvider;
          },
        ),
        ChangeNotifierProxyProvider<BleManagerProvider, TelemetryProvider>(
          create: (_) => TelemetryProvider(),
          update: (_, bleProvider, telemetryProvider) {
            telemetryProvider ??= TelemetryProvider();
            telemetryProvider.subscribeToStreams(
              telemetryStream: bleProvider.telemetryStream,
              connectionEventsStream: bleProvider.connectionEventsStream,
            );
            return telemetryProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SmartHouseApp(),
    ),
  );
}

/// The root widget of the Smart House BLE application.
class SmartHouseApp extends StatelessWidget {
  const SmartHouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.isDarkMode
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const SplashScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/connection/connection_provider.dart';
import 'state/device/device_provider.dart';
import 'state/theme/theme_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
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
    final theme = themeProvider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Smart House BLE'),
        ),
        body: const Center(
          child: Text(
            'System Core Initialized',
          ),
        ),
      ),
    );
  }
}

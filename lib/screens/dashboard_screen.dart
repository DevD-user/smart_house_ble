import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
import '../state/theme/theme_provider.dart';

/// The main dashboard screen showing BLE status and connected smart devices.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart House BLE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Connection Status Card
              Consumer<ConnectionProvider>(
                builder: (context, connectionProvider, child) {
                  final statusText = _getBleStatusText(connectionProvider.connectionState);
                  return SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connected Devices: ${connectionProvider.connectedDeviceCount}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'BLE Status: $statusText',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 2. Section Title: Devices
              Text(
                'Devices',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Dynamic Devices List
              Expanded(
                child: Consumer<DeviceProvider>(
                  builder: (context, deviceProvider, child) {
                    final devicesList = deviceProvider.devices.values.toList();

                    if (devicesList.isEmpty) {
                      return const Center(
                        child: Text('No devices connected'),
                      );
                    }

                    return ListView.builder(
                      itemCount: devicesList.length,
                      itemBuilder: (context, index) {
                        // Creating a temporary Card widget for each device
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Device Name Placeholder',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Status Placeholder',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    Text(
                                      'Voltage Placeholder',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 4. Bottom Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // No onPressed logic yet
                      },
                      child: const Text('Start Simulation'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // No navigation yet
                      },
                      child: const Text('Diagnostics'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBleStatusText(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.idle:
        return 'Idle';
      case BleConnectionState.scanning:
        return 'Scanning';
      case BleConnectionState.connecting:
        return 'Connecting';
      case BleConnectionState.connected:
        return 'Connected';
      case BleConnectionState.reconnecting:
        return 'Reconnecting';
      case BleConnectionState.error:
        return 'Error';
    }
  }
}

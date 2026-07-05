import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/smart_device.dart';
import '../state/ble/ble_manager_provider.dart';
import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
import '../state/theme/theme_provider.dart';
import 'device_detail_page.dart';

/// Data class holding current theme palette colors to avoid hardcoded colors.
class ThemePalette {
  final Color background;
  final Color card;
  final Color accent;
  final Color secondaryAccent;
  final Color text;
  final Color subText;
  final bool isDark;

  const ThemePalette({
    required this.background,
    required this.card,
    required this.accent,
    required this.secondaryAccent,
    required this.text,
    required this.subText,
    required this.isDark,
  });
}

/// The Devices tab page displaying discovered BLE nodes, scanning indicators, and empty state.
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final palette = ThemePalette(
      background: isDark ? const Color(0xFF0F1115) : const Color(0xFFF7F9FC),
      card: isDark ? const Color(0xFF1A1D24) : Colors.white,
      accent: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E),
      secondaryAccent: isDark ? const Color(0xFF2979FF) : const Color(0xFF0288D1),
      text: isDark ? Colors.white : const Color(0xFF0F1115),
      subText: isDark ? Colors.white54 : Colors.black54,
      isDark: isDark,
    );

    final connectionProvider = context.watch<ConnectionProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final bleProvider = context.read<BleManagerProvider>();

    final isScanning = connectionProvider.isScanning;
    final devicesList = deviceProvider.devices.values.toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Devices',
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: palette.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: isScanning
                ? TextButton.icon(
                    onPressed: () => bleProvider.stopSimulation(),
                    icon: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                      ),
                    ),
                    label: Text(
                      'Stop Scan',
                      style: TextStyle(
                        color: palette.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () => bleProvider.startSimulation(),
                    icon: Icon(Icons.refresh, color: palette.accent),
                    label: Text(
                      'Scan',
                      style: TextStyle(
                        color: palette.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isScanning)
              LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
              ),
            Expanded(
              child: devicesList.isEmpty
                  ? _buildEmptyState(context, palette, bleProvider)
                  : _buildDeviceList(context, devicesList, palette, connectionProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemePalette palette,
    BleManagerProvider bleProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 80,
              color: palette.isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 24),
            Text(
              'No Devices Discovered',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scanning to find nearby smart household monitoring and control nodes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: palette.subText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => bleProvider.startSimulation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.search,
                color: palette.isDark ? Colors.black : Colors.white,
              ),
              label: const Text(
                'Start Scanning',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    List<SmartDevice> devices,
    ThemePalette palette,
    ConnectionProvider connectionProvider,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = devices[index];
        final deviceConnectionState = connectionProvider.getDeviceConnectionState(device.deviceId);

        return Card(
          color: palette.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: palette.isDark ? Colors.white10 : Colors.black12,
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DeviceDetailPlaceholderPage(device: device),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.router,
                      color: palette.isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.deviceId,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: palette.subText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(deviceConnectionState),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(deviceConnectionState),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: palette.subText,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: palette.subText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getFormattedTime(device.lastSeen),
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.subText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: palette.subText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.connected:
        return Colors.green;
      case BleConnectionState.connecting:
      case BleConnectionState.reconnecting:
        return Colors.amber;
      case BleConnectionState.error:
        return Colors.red;
      case BleConnectionState.scanning:
        return Colors.blue;
      case BleConnectionState.idle:
        return Colors.grey;
    }
  }

  String _getStatusText(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.connected:
        return 'Connected';
      case BleConnectionState.connecting:
        return 'Connecting...';
      case BleConnectionState.reconnecting:
        return 'Reconnecting...';
      case BleConnectionState.error:
        return 'Error';
      case BleConnectionState.scanning:
        return 'Discovered';
      case BleConnectionState.idle:
        return 'Ready';
    }
  }

  String _getFormattedTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

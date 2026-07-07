import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
import '../state/telemetry/telemetry_provider.dart';
import '../state/theme/theme_provider.dart';
import 'device_detail_page.dart';

/// Data class holding current theme palette colors to avoid hardcoded colors in the tree.
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Resolve global theme state once
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // 2. Map current theme state to approved design specification colors
    final palette = ThemePalette(
      background: isDark ? const Color(0xFF0F1115) : const Color(0xFFF7F9FC),
      card: isDark ? const Color(0xFF1A1D24) : Colors.white,
      accent: isDark ? const Color(0xFF00E5FF) : const Color(0xFF1A237E),
      secondaryAccent: isDark ? const Color(0xFF2979FF) : const Color(0xFF0288D1),
      text: isDark ? Colors.white : const Color(0xFF0F1115),
      subText: isDark ? Colors.white54 : Colors.black54,
      isDark: isDark,
    );

    // 3. Watch state from providers
    final deviceProvider = context.watch<DeviceProvider>();
    final connectionProvider = context.watch<ConnectionProvider>();
    final telemetryProvider = context.watch<TelemetryProvider>();
    final devicesList = deviceProvider.devices.values.toList();

    // 4. Compute last sync time on-the-fly across telemetry & connection activity
    DateTime? latestSync;

    // Check latest telemetry timestamp across all devices
    final allLatestReadings = telemetryProvider.getAllLatest();
    for (final deviceMap in allLatestReadings.values) {
      for (final reading in deviceMap.values) {
        if (latestSync == null || reading.timestamp.isAfter(latestSync)) {
          latestSync = reading.timestamp;
        }
      }
    }

    // Check latest connection activity timestamp across all currently connected devices
    for (final device in devicesList) {
      final isConnected = connectionProvider.getDeviceConnectionState(device.deviceId) == BleConnectionState.connected;
      if (isConnected) {
        if (latestSync == null || device.lastSeen.isAfter(latestSync)) {
          latestSync = device.lastSeen;
        }
      }
    }

    final String lastSyncText;
    if (latestSync == null) {
      lastSyncText = 'Never';
    } else {
      lastSyncText = '${latestSync.hour.toString().padLeft(2, '0')}:'
          '${latestSync.minute.toString().padLeft(2, '0')}:'
          '${latestSync.second.toString().padLeft(2, '0')}';
    }

    final totalDevices = devicesList.length;
    final connectedDevices = connectionProvider.connectedDeviceCount;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Smart House BLE',
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: palette.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              palette.isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: palette.text,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SafeArea(
        child: totalDevices == 0
            ? _buildEmptyState(context, palette)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HouseOverviewCard(
                      palette: palette,
                      connectedCount: connectedDevices,
                      totalCount: totalDevices,
                      lastSync: lastSyncText,
                      alerts: 'No alerts',
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Devices',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalDevices,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final device = devicesList[index];
                        final connectionState = connectionProvider.getDeviceConnectionState(device.deviceId);
                        final isConnected = connectionState == BleConnectionState.connected;

                        return Card(
                          color: palette.card,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: palette.isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.04),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DeviceDetailPlaceholderPage(device: device),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isConnected
                                          ? palette.accent.withValues(alpha: 0.08)
                                          : (palette.isDark
                                              ? Colors.white.withValues(alpha: 0.03)
                                              : Colors.black.withValues(alpha: 0.02)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.router,
                                      color: isConnected
                                          ? palette.accent
                                          : (palette.isDark ? Colors.white38 : Colors.black38),
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isConnected ? Colors.green : Colors.redAccent,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isConnected ? 'Connected' : 'Disconnected',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isConnected ? Colors.green : palette.subText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right,
                                    color: palette.text.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemePalette palette) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Icon(
                Icons.sensors_off_rounded,
                size: 64,
                color: palette.subText.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Registered Devices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You don\'t have any smart home devices registered yet. Go to the "Devices" tab to scan and connect a device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: palette.subText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HouseOverviewCard extends StatelessWidget {
  final ThemePalette palette;
  final int connectedCount;
  final int totalCount;
  final String lastSync;
  final String alerts;

  const HouseOverviewCard({
    super.key,
    required this.palette,
    required this.connectedCount,
    required this.totalCount,
    required this.lastSync,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = connectedCount > 0;

    return Card(
      color: palette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'House Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHealthy
                        ? Colors.green.withValues(alpha: 0.08)
                        : Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHealthy
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.redAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHealthy ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isHealthy ? 'Healthy' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isHealthy ? Colors.green : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.devices,
                    label: 'Connected',
                    value: '$connectedCount / $totalCount',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.sync,
                    label: 'Last Sync',
                    value: lastSync,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.notifications_none,
                    label: 'Alerts',
                    value: alerts,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: palette.accent,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: palette.subText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: palette.text,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

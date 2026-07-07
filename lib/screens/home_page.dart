import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/smart_device.dart';
import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
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
    final devicesList = deviceProvider.devices.values.toList();

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
        child: devicesList.isEmpty
            ? _buildEmptyState(context, palette)
            : _buildDeviceList(context, devicesList, palette, connectionProvider),
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

  Widget _buildDeviceList(
    BuildContext context,
    List<SmartDevice> devices,
    ThemePalette palette,
    ConnectionProvider connectionProvider,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final device = devices[index];
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
                  // Decorative leading icon container
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
                  // Middle section with device details
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
                        // Connection status badge
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
                  // Chevron icon indicating tappability
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
    );
  }
}

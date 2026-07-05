import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/smart_device.dart';
import '../state/theme/theme_provider.dart';

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

/// A placeholder details page displayed when a device card is tapped.
class DeviceDetailPlaceholderPage extends StatelessWidget {
  final SmartDevice device;

  const DeviceDetailPlaceholderPage({super.key, required this.device});

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

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          device.deviceName,
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: palette.text),
        backgroundColor: palette.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Device Info Card
              Card(
                color: palette.card,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: palette.isDark ? Colors.white10 : Colors.black12,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: palette.isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings_remote,
                          size: 30,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.deviceName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              device.deviceId,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                                color: palette.subText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Info Alert / Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.secondaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: palette.secondaryAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: palette.secondaryAccent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developer Note',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Active BLE connection control, telemetry graph visualizations, and custom configurations are out of scope for the current design phase and will be integrated in subsequent roadmap tickets.',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.subText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Placeholder telemetry indicators
              Text(
                'Telemetry overview (Pending)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 12),
              _buildPlaceholderRow(palette, 'Voltage Level', '-- V'),
              const SizedBox(height: 12),
              _buildPlaceholderRow(palette, 'Signal Strength (RSSI)', '-- dBm'),
              const SizedBox(height: 12),
              _buildPlaceholderRow(palette, 'Last Handshake', 'Pending Connection'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderRow(ThemePalette palette, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: palette.subText,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

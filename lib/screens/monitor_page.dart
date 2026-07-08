import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/capability_types.dart';
import '../models/smart_device.dart';
import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
import '../state/telemetry/telemetry_provider.dart';
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

/// The Monitor tab page showing live, dynamic telemetry from all connected devices.
class MonitorPage extends StatelessWidget {
  const MonitorPage({super.key});

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

    final deviceProvider = context.watch<DeviceProvider>();
    final connectionProvider = context.watch<ConnectionProvider>();
    final telemetryProvider = context.watch<TelemetryProvider>();

    // Filter connected devices in deterministic registration (insertion) order
    final connectedDevices = deviceProvider.devices.values
        .where((device) =>
            connectionProvider.getDeviceConnectionState(device.deviceId) ==
            BleConnectionState.connected)
        .toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Live Monitor',
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: palette.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: connectedDevices.isEmpty
            ? _buildEmptyState(context, palette)
            : ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: connectedDevices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final device = connectedDevices[index];
                  final readingsMap = telemetryProvider.getAllLatest()[device.deviceId] ?? const {};
                  return _buildDeviceTelemetryCard(context, device, readingsMap, palette);
                },
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
              'No Live Telemetry',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No devices are currently sending live telemetry. Connect a device from the Devices tab to begin monitoring.',
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

  Widget _buildDeviceTelemetryCard(
    BuildContext context,
    SmartDevice device,
    Map<String, dynamic> readingsMap,
    ThemePalette palette,
  ) {
    final hasTelemetry = readingsMap.isNotEmpty;

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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Name, ID, Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: TextStyle(
                            fontSize: 18,
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge matching connected + telemetry state
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasTelemetry
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasTelemetry
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasTelemetry ? Colors.green : Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasTelemetry ? 'Live' : 'Waiting',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasTelemetry ? Colors.green : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Telemetry Section
              if (!hasTelemetry)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Waiting for telemetry...',
                        style: TextStyle(
                          fontSize: 14,
                          color: palette.subText,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (() {
                    final sortedReadings = readingsMap.values.toList()
                      ..sort((a, b) {
                        final aType = CapabilityType.values.cast<CapabilityType?>().firstWhere(
                          (type) => type?.name.toLowerCase() == a.sensorType.toLowerCase(),
                          orElse: () => null,
                        );
                        final bType = CapabilityType.values.cast<CapabilityType?>().firstWhere(
                          (type) => type?.name.toLowerCase() == b.sensorType.toLowerCase(),
                          orElse: () => null,
                        );
                        final aIndex = aType?.index ?? 999;
                        final bIndex = bType?.index ?? 999;
                        if (aIndex != bIndex) {
                          return aIndex.compareTo(bIndex);
                        }
                        return a.sensorType.compareTo(b.sensorType);
                      });
                    return sortedReadings.map((reading) {
                      final String displayValue = reading.unit != null
                          ? '${reading.value} ${reading.unit}'
                          : '${reading.value}';
                      
                      // Match CapabilityType dynamically to resolve displayName
                      final String sensorLabel;
                      final capType = CapabilityType.values.cast<CapabilityType?>().firstWhere(
                        (type) => type?.name.toLowerCase() == reading.sensorType.toLowerCase(),
                        orElse: () => null,
                      );
                      if (capType != null) {
                        sensorLabel = capType.displayName;
                      } else {
                        sensorLabel = reading.sensorType.isNotEmpty
                            ? '${reading.sensorType[0].toUpperCase()}${reading.sensorType.substring(1)} Sensor'
                            : 'Sensor';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sensorLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: palette.subText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayValue,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: palette.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    });
                  })().toList(),
                ),

              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5, color: Colors.white12),
              const SizedBox(height: 16),

              // Future metrics visual space reservation without fake values
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: palette.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    style: BorderStyle.solid,
                  ),
                  color: palette.isDark
                      ? Colors.white.withValues(alpha: 0.01)
                      : Colors.black.withValues(alpha: 0.01),
                ),
                child: Center(
                  child: Text(
                    'Future Telemetry Expansion Area',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: palette.subText.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

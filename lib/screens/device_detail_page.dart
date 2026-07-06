import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/smart_device.dart';
import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
import '../state/telemetry/telemetry_provider.dart';
import '../services/ble/payload_parser.dart';
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

/// The Device Detail screen showing live status, RSSI, and rolling telemetry graph.
class DeviceDetailPlaceholderPage extends StatelessWidget {
  final SmartDevice device;
  static const String _sensorType = 'voltage';

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

    return Consumer3<DeviceProvider, ConnectionProvider, TelemetryProvider>(
      builder: (context, deviceProvider, connectionProvider, telemetryProvider, child) {
        // Look up latest device metadata dynamically
        final latestDevice = deviceProvider.getDevice(device.deviceId) ?? device;
        final connectionState = connectionProvider.getDeviceConnectionState(device.deviceId);
        final latestReading = telemetryProvider.getLatest(device.deviceId, _sensorType);
        final buffer = telemetryProvider.getBuffer(device.deviceId, _sensorType);

        final String statusText;
        final Color statusColor;
        switch (connectionState) {
          case BleConnectionState.connected:
            statusText = 'Connected';
            statusColor = Colors.green;
            break;
          case BleConnectionState.connecting:
            statusText = 'Connecting...';
            statusColor = Colors.amber;
            break;
          case BleConnectionState.reconnecting:
            statusText = 'Reconnecting...';
            statusColor = Colors.orange;
            break;
          case BleConnectionState.error:
            statusText = 'Connection Error';
            statusColor = Colors.red;
            break;
          default:
            statusText = 'Disconnected';
            statusColor = Colors.redAccent;
        }

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.background,
            elevation: 0,
            title: Text(
              'Device Detail',
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: palette.text),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DeviceHeaderCard(
                    deviceName: latestDevice.deviceName,
                    deviceId: latestDevice.deviceId,
                    statusText: statusText,
                    statusColor: statusColor,
                    palette: palette,
                  ),
                  const SizedBox(height: 16.0),
                  ConnectionMetricsCard(
                    statusText: statusText,
                    statusColor: statusColor,
                    palette: palette,
                  ),
                  const SizedBox(height: 16.0),
                  TelemetrySummaryCard(
                    reading: latestReading,
                    isConnected: connectionState == BleConnectionState.connected,
                    palette: palette,
                  ),
                  const SizedBox(height: 16.0),
                  TelemetryGraphCard(
                    buffer: buffer,
                    isConnected: connectionState == BleConnectionState.connected,
                    palette: palette,
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

/// A card widget showing high-level device information and status badge.
class DeviceHeaderCard extends StatelessWidget {
  final String deviceName;
  final String deviceId;
  final String statusText;
  final Color statusColor;
  final ThemePalette palette;

  const DeviceHeaderCard({
    super.key,
    required this.deviceName,
    required this.deviceId,
    required this.statusText,
    required this.statusColor,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_remote,
                size: 28,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceId,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: palette.subText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card widget displaying detailed connection parameters and RSSI.
class ConnectionMetricsCard extends StatelessWidget {
  final String statusText;
  final Color statusColor;
  final ThemePalette palette;

  const ConnectionMetricsCard({
    super.key,
    required this.statusText,
    required this.statusColor,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signal & Connection Metrics',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetricRow('Connection State', statusText, statusColor),
            const Divider(height: 24, thickness: 0.5, color: Colors.white12),
            _buildMetricRow(
              'Signal Strength (RSSI)',
              'N/A (Unavailable)',
              palette.subText,
              subtitle: 'RSSI is temporarily unavailable',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: palette.subText,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: palette.subText.withValues(alpha: 0.7),
            ),
          ),
        ]
      ],
    );
  }
}

/// A card widget showing telemetry value details and its last sync timestamp.
class TelemetrySummaryCard extends StatelessWidget {
  final TelemetryReading? reading;
  final bool isConnected;
  final ThemePalette palette;

  const TelemetrySummaryCard({
    super.key,
    required this.reading,
    required this.isConnected,
    required this.palette,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final hasData = reading != null;
    final displayValue = hasData ? '${reading!.value}' : (isConnected ? 'Waiting...' : 'N/A');
    final displayTime = hasData ? _formatTime(reading!.timestamp) : (isConnected ? 'Waiting...' : 'Offline');

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Telemetry Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SENSOR TYPE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: palette.subText,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Voltage Sensor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RAW VALUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: palette.subText,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isConnected ? palette.accent : palette.subText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5, color: Colors.white12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last Updated',
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.subText,
                  ),
                ),
                Text(
                  displayTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A card widget encapsulating the fl_chart LineChart for live telemetry plotting.
class TelemetryGraphCard extends StatelessWidget {
  final List<TelemetryReading> buffer;
  final bool isConnected;
  final ThemePalette palette;

  const TelemetryGraphCard({
    super.key,
    required this.buffer,
    required this.isConnected,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final showPlaceholder = buffer.isEmpty;

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Telemetry (Last 30s)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: showPlaceholder
                  ? _buildPlaceholder()
                  : _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isConnected) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Waiting for telemetry stream...',
              style: TextStyle(
                fontSize: 13,
                color: palette.subText,
              ),
            ),
          ] else ...[
            Icon(
              Icons.trending_flat,
              size: 32,
              color: palette.subText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No active telemetry data (Offline)',
              style: TextStyle(
                fontSize: 13,
                color: palette.subText,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildChart() {
    final now = DateTime.now();
    final referenceTime = now.subtract(const Duration(seconds: 30));

    final spots = buffer.map((reading) {
      final double x = reading.timestamp.difference(referenceTime).inMilliseconds / 1000.0;
      final double y = reading.value.toDouble();
      return FlSpot(x.clamp(0.0, 30.0), y.clamp(0.0, 4095.0));
    }).toList();

    // Sort spots by X to ensure LineChart renders correctly without drawing artifacts
    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 30,
        minY: 0,
        maxY: 4095,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1000,
          verticalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final int secondsAgo = (30 - value).round();
                if (secondsAgo == 0) {
                  return Text('Now', style: TextStyle(color: palette.subText, fontSize: 10));
                }
                return Text('-${secondsAgo}s', style: TextStyle(color: palette.subText, fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1000,
              getTitlesWidget: (value, meta) {
                // Skip displaying the max value (4095) which sits too close to 4000 and causes overlap
                if (value >= 4095) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: palette.subText, fontSize: 10),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white10, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: palette.accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: palette.accent.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

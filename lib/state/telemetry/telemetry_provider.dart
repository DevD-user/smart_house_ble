import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/ble/payload_parser.dart';

/// State management provider for tracking live, multi-device sensor telemetry.
class TelemetryProvider extends ChangeNotifier {
  // Latest telemetry readings: Map<deviceId, Map<sensorType, TelemetryReading>>
  final Map<String, Map<String, TelemetryReading>> _latestReadings = {};

  // Rolling in-memory buffers: Map<deviceId, Map<sensorType, List<TelemetryReading>>>
  final Map<String, Map<String, List<TelemetryReading>>> _buffers = {};

  StreamSubscription<TelemetryReading>? _telemetrySubscription;
  StreamSubscription<String>? _connectionEventsSubscription;
  Stream<TelemetryReading>? _currentTelemetryStream;
  Stream<String>? _currentConnectionStream;

  /// Subscribes to the given streams for telemetry and connection control events.
  void subscribeToStreams({
    Stream<TelemetryReading>? telemetryStream,
    Stream<String>? connectionEventsStream,
  }) {
    // Handle telemetry stream updates
    if (_currentTelemetryStream != telemetryStream) {
      _telemetrySubscription?.cancel();
      _currentTelemetryStream = telemetryStream;
      if (telemetryStream != null) {
        _telemetrySubscription = telemetryStream.listen(addReading);
      }
    }

    // Handle connection events stream updates
    if (_currentConnectionStream != connectionEventsStream) {
      _connectionEventsSubscription?.cancel();
      _currentConnectionStream = connectionEventsStream;
      if (connectionEventsStream != null) {
        _connectionEventsSubscription = connectionEventsStream.listen(clearDeviceTelemetry);
      }
    }
  }

  /// Returns the latest [TelemetryReading] for a given device and sensor type.
  /// Returns `null` if no readings have been received yet.
  TelemetryReading? getLatest(String deviceId, String sensorType) {
    return _latestReadings[deviceId]?[sensorType];
  }

  /// Returns a read-only list containing the rolling buffer of telemetry readings
  /// from the last 30 seconds for the given device and sensor type.
  List<TelemetryReading> getBuffer(String deviceId, String sensorType) {
    final buffer = _buffers[deviceId]?[sensorType];
    if (buffer == null) return const [];

    // Clean up stale readings (older than 30 seconds) before returning
    final limit = DateTime.now().subtract(const Duration(seconds: 30));
    buffer.removeWhere((reading) => reading.timestamp.isBefore(limit));
    return List.unmodifiable(buffer);
  }

  /// Returns an unmodifiable snapshot of the latest readings across all devices.
  /// Structure: Map of deviceId to Map of sensorType to TelemetryReading.
  Map<String, Map<String, TelemetryReading>> getAllLatest() {
    final Map<String, Map<String, TelemetryReading>> copy = {};
    _latestReadings.forEach((deviceId, sensorMap) {
      copy[deviceId] = Map.unmodifiable(sensorMap);
    });
    return Map.unmodifiable(copy);
  }

  /// Adds a new [TelemetryReading] to the provider, updating the latest reading
  /// and appending it to the rolling buffer. Triggers [notifyListeners].
  void addReading(TelemetryReading reading) {
    final deviceId = reading.deviceId;
    final sensorType = reading.sensorType;

    // Update latest reading
    _latestReadings.putIfAbsent(deviceId, () => {})[sensorType] = reading;

    // Update buffer
    final deviceBuffers = _buffers.putIfAbsent(deviceId, () => {});
    final buffer = deviceBuffers.putIfAbsent(sensorType, () => []);
    buffer.add(reading);

    // Maintain buffer limit (remove readings older than 30 seconds)
    final limit = DateTime.now().subtract(const Duration(seconds: 30));
    buffer.removeWhere((r) => r.timestamp.isBefore(limit));

    notifyListeners();
  }

  /// Clears telemetry data (both latest and buffer) for a specific device.
  void clearDeviceTelemetry(String deviceId) {
    if (_latestReadings.containsKey(deviceId) || _buffers.containsKey(deviceId)) {
      _latestReadings.remove(deviceId);
      _buffers.remove(deviceId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _connectionEventsSubscription?.cancel();
    super.dispose();
  }
}

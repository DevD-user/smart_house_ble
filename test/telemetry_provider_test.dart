import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_house_ble/services/ble/payload_parser.dart';
import 'package:smart_house_ble/state/telemetry/telemetry_provider.dart';

void main() {
  group('TelemetryProvider Tests', () {
    test('addReading updates latest reading and buffer', () {
      final provider = TelemetryProvider();
      final reading = TelemetryReading(
        deviceId: 'device_1',
        sensorType: 'voltage',
        value: 1234,
        timestamp: DateTime.now(),
      );

      provider.addReading(reading);

      expect(provider.getLatest('device_1', 'voltage'), reading);
      final buffer = provider.getBuffer('device_1', 'voltage');
      expect(buffer.length, 1);
      expect(buffer.first, reading);

      final allLatest = provider.getAllLatest();
      expect(allLatest['device_1']?['voltage'], reading);
    });

    test('stale readings are evicted from rolling buffer', () {
      final provider = TelemetryProvider();
      final now = DateTime.now();

      final oldReading = TelemetryReading(
        deviceId: 'device_1',
        sensorType: 'voltage',
        value: 1000,
        timestamp: now.subtract(const Duration(seconds: 31)),
      );

      final freshReading = TelemetryReading(
        deviceId: 'device_1',
        sensorType: 'voltage',
        value: 2000,
        timestamp: now,
      );

      // Add old reading first
      provider.addReading(oldReading);
      expect(provider.getBuffer('device_1', 'voltage').length, 0); // Already stale relative to now!

      // Reset provider to test adding within the window then aging
      final provider2 = TelemetryProvider();
      // Add fresh reading
      provider2.addReading(freshReading);
      expect(provider2.getBuffer('device_1', 'voltage').length, 1);
    });

    test('different devices remain isolated', () {
      final provider = TelemetryProvider();
      final reading1 = TelemetryReading(
        deviceId: 'device_1',
        sensorType: 'voltage',
        value: 1234,
        timestamp: DateTime.now(),
      );
      final reading2 = TelemetryReading(
        deviceId: 'device_2',
        sensorType: 'voltage',
        value: 5678,
        timestamp: DateTime.now(),
      );

      provider.addReading(reading1);
      provider.addReading(reading2);

      expect(provider.getLatest('device_1', 'voltage'), reading1);
      expect(provider.getLatest('device_2', 'voltage'), reading2);

      expect(provider.getBuffer('device_1', 'voltage').first, reading1);
      expect(provider.getBuffer('device_2', 'voltage').first, reading2);
    });

    test('connectionEventsStream clears telemetry for device', () async {
      final provider = TelemetryProvider();
      final telemetryController = StreamController<TelemetryReading>.broadcast();
      final connectionEventsController = StreamController<String>.broadcast();

      provider.subscribeToStreams(
        telemetryStream: telemetryController.stream,
        connectionEventsStream: connectionEventsController.stream,
      );

      final reading = TelemetryReading(
        deviceId: 'device_1',
        sensorType: 'voltage',
        value: 1234,
        timestamp: DateTime.now(),
      );

      // Push telemetry reading
      telemetryController.add(reading);
      await Future.delayed(Duration.zero); // yield for stream listeners

      expect(provider.getLatest('device_1', 'voltage'), reading);

      // Trigger connection event (new connection starts)
      connectionEventsController.add('device_1');
      await Future.delayed(Duration.zero); // yield

      expect(provider.getLatest('device_1', 'voltage'), isNull);
      expect(provider.getBuffer('device_1', 'voltage'), isEmpty);

      await telemetryController.close();
      await connectionEventsController.close();
      provider.dispose();
    });

    test('clearDeviceTelemetry removes all data for device', () {
      final provider = TelemetryProvider();
      final reading = TelemetryReading(
        deviceId: 'device_1',
        sensorType: 'voltage',
        value: 1234,
        timestamp: DateTime.now(),
      );

      provider.addReading(reading);
      expect(provider.getLatest('device_1', 'voltage'), isNotNull);

      provider.clearDeviceTelemetry('device_1');
      expect(provider.getLatest('device_1', 'voltage'), isNull);
      expect(provider.getBuffer('device_1', 'voltage'), isEmpty);
    });
  });
}

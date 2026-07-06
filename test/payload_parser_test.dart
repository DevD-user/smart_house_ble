import 'package:flutter_test/flutter_test.dart';
import 'package:smart_house_ble/services/ble/payload_parser.dart';

void main() {
  group('PayloadParser.parse Tests', () {
    const String deviceId = 'test_device_id';
    const String sensorType = 'voltage';

    test('decodes standard 2-byte payload correctly (Test Case 1: 3066)', () {
      final reading = PayloadParser.parse(
        deviceId: deviceId,
        sensorType: sensorType,
        bytes: [0xFA, 0x0B],
      );

      expect(reading.deviceId, deviceId);
      expect(reading.sensorType, sensorType);
      expect(reading.value, 3066);
      expect(reading.timestamp, isNotNull);
    });

    test('decodes standard 2-byte payload correctly (Test Case 2: 65535)', () {
      final reading = PayloadParser.parse(
        deviceId: deviceId,
        sensorType: sensorType,
        bytes: [0xFF, 0xFF],
      );

      expect(reading.value, 65535);
    });

    test('decodes 2-byte payload with zero correctly', () {
      final reading = PayloadParser.parse(
        deviceId: deviceId,
        sensorType: sensorType,
        bytes: [0x00, 0x00],
      );

      expect(reading.value, 0);
    });

    test('throws FormatException on truncated 1-byte payload', () {
      expect(
        () => PayloadParser.parse(
          deviceId: deviceId,
          sensorType: sensorType,
          bytes: [0xFA],
        ),
        throwsFormatException,
      );
    });

    test('throws FormatException on empty payload', () {
      expect(
        () => PayloadParser.parse(
          deviceId: deviceId,
          sensorType: sensorType,
          bytes: [],
        ),
        throwsFormatException,
      );
    });

    test('decodes overlength payload by using only the first 2 bytes and ignoring trailing bytes', () {
      final reading = PayloadParser.parse(
        deviceId: deviceId,
        sensorType: sensorType,
        bytes: [0xFA, 0x0B, 0x01],
      );

      expect(reading.value, 3066);
    });
  });
}

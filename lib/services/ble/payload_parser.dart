/// Represents a telemetry data point from a BLE device sensor.
class TelemetryReading {
  final String deviceId;
  final String sensorType;
  final int value;
  final DateTime timestamp;
  final String? unit;
  final String? quality;

  TelemetryReading({
    required this.deviceId,
    required this.sensorType,
    required this.value,
    required this.timestamp,
    this.unit,
    this.quality,
  });
}

/// Generic payload parsing utility for BLE notify payloads.
class PayloadParser {
  /// Parses raw BLE notify bytes into a typed [TelemetryReading] using little-endian uint16 decoding.
  ///
  /// Throws a [FormatException] if the payload contains fewer than 2 bytes.
  /// If the payload contains more than 2 bytes, it decodes the first 2 bytes and ignores trailing bytes.
  static TelemetryReading parse({
    required String deviceId,
    required String sensorType,
    required List<int> bytes,
    String? unit,
    String? quality,
  }) {
    if (bytes.length < 2) {
      throw FormatException(
        'Invalid payload length: expected at least 2 bytes, got ${bytes.length} bytes.',
      );
    }

    // Decode little-endian uint16 value from the first two bytes
    final int value = bytes[0] | (bytes[1] << 8);

    return TelemetryReading(
      deviceId: deviceId,
      sensorType: sensorType,
      value: value,
      timestamp: DateTime.now(),
      unit: unit,
      quality: quality,
    );
  }
}

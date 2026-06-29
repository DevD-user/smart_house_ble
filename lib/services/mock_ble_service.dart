import 'dart:async';
import 'dart:math';

/// A mock service simulating Bluetooth Low Energy (BLE) device telemetry data streaming.
class MockBleService {
  Timer? _mockTimer;

  final StreamController<Map<String, dynamic>> _deviceStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Exposes the stream of mock device telemetry events.
  Stream<Map<String, dynamic>> get deviceStream => _deviceStreamController.stream;

  /// Starts periodic mock telemetry data streaming every 2 seconds.
  void startMockStreaming() {
    _mockTimer?.cancel();
    final random = Random();

    _mockTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Generate Node_A telemetry (voltage: 1.5 to 3.3, battery: 60 to 100)
      final voltageA = 1.5 + random.nextDouble() * (3.3 - 1.5);
      final batteryA = 60 + random.nextInt(41); // 41 is exclusive, range [0, 40] -> [60, 100]
      _deviceStreamController.add({
        'deviceId': 'Node_A',
        'sensorId': 1,
        'value': double.parse(voltageA.toStringAsFixed(2)),
        'battery': batteryA,
      });

      // Generate Node_B telemetry (voltage: 1.0 to 3.3, battery: 50 to 100)
      final voltageB = 1.0 + random.nextDouble() * (3.3 - 1.0);
      final batteryB = 50 + random.nextInt(51); // 51 is exclusive, range [0, 50] -> [50, 100]
      _deviceStreamController.add({
        'deviceId': 'Node_B',
        'sensorId': 1,
        'value': double.parse(voltageB.toStringAsFixed(2)),
        'battery': batteryB,
      });
    });
  }

  /// Stops the mock streaming timer.
  void stopMockStreaming() {
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  /// Releases resources by stopping the timer and closing the stream controller.
  void dispose() {
    _mockTimer?.cancel();
    _mockTimer = null;
    _deviceStreamController.close();
  }
}

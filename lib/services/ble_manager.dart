import 'dart:async';

import '../models/capability_types.dart';
import '../models/device_capability.dart';
import '../models/smart_device.dart';
import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
import 'mock_ble_service.dart';

/// Manager for handling Bluetooth Low Energy (BLE) operations and stream telemetry.
class BleManager {
  final MockBleService _mockBleService;
  final DeviceProvider _deviceProvider;
  final ConnectionProvider _connectionProvider;
  StreamSubscription? _deviceSubscription;

  /// Creates a [BleManager] and initializes the internal [MockBleService].
  BleManager({
    required DeviceProvider deviceProvider,
    required ConnectionProvider connectionProvider,
  })  : _deviceProvider = deviceProvider,
        _connectionProvider = connectionProvider,
        _mockBleService = MockBleService();

  /// Starts scanning, starts the mock telemetry stream, and listens to the device telemetry stream.
  void startMockBle() {
    _connectionProvider.startScanning();
    _mockBleService.startMockStreaming();

    _deviceSubscription?.cancel();
    _deviceSubscription = _mockBleService.deviceStream.listen((packet) {
      final String deviceId = packet['deviceId'] as String;
      final int sensorId = packet['sensorId'] as int;
      final dynamic value = packet['value'];

      final existingDevice = _deviceProvider.getDevice(deviceId);

      if (existingDevice == null) {
        final voltageCap = DeviceCapability(
          capabilityType: CapabilityType.voltage,
          currentValue: value,
          lastUpdated: DateTime.now(),
          isAvailable: true,
          unit: 'V',
        );

        final newDevice = SmartDevice(
          deviceId: deviceId,
          deviceName: deviceId == 'Node_A'
              ? 'Node A'
              : (deviceId == 'Node_B' ? 'Node B' : deviceId),
          isConnected: true,
          lastSeen: DateTime.now(),
          capabilities: {
            CapabilityType.voltage.id: voltageCap,
          },
        );

        _deviceProvider.addDevice(newDevice);
      } else {
        existingDevice.markConnected();
        _deviceProvider.updateDeviceCapability(deviceId, sensorId, value);
      }

      final connectedCount =
          _deviceProvider.devices.values.where((d) => d.isConnected).length;
      _connectionProvider.setConnected(connectedCount);
    });
  }

  /// Stops mock streaming, cancels the active stream subscription, and resets connection state.
  void stopMockBle() {
    _mockBleService.stopMockStreaming();
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _connectionProvider.reset();
  }

  /// Disposes of the active stream subscription and underlying mock BLE service resources.
  void dispose() {
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _mockBleService.dispose();
  }
}

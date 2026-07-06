import 'package:flutter/material.dart';

import '../../services/ble_manager.dart';
import '../connection/connection_provider.dart';
import '../device/device_provider.dart';

/// Provider that wraps and exposes BLE manager control operations.
class BleManagerProvider extends ChangeNotifier {
  BleManager? _bleManager;
  ConnectionProvider? _connectionProvider;

  /// Initializes the BleManager if it hasn't been initialized yet.
  void initialize({
    required DeviceProvider deviceProvider,
    required ConnectionProvider connectionProvider,
  }) {
    _connectionProvider = connectionProvider;
    _bleManager ??= BleManager(
      deviceProvider,
      connectionProvider,
    );
  }

  /// Gets the connection state for a specific device.
  BleConnectionState getDeviceConnectionState(String deviceId) {
    return _connectionProvider?.getDeviceConnectionState(deviceId) ??
        BleConnectionState.idle;
  }

  /// Sets the connection state for a specific device.
  void setDeviceConnectionState(String deviceId, BleConnectionState state) {
    _connectionProvider?.setDeviceConnectionState(deviceId, state);
  }

  /// Starts the mock BLE simulation.
  void startSimulation() {
    _bleManager?.startMockBle();
  }

  /// Stops the mock BLE simulation.
  void stopSimulation() {
    _bleManager?.stopMockBle();
  }

  /// Connects to a device by its ID.
  Future<void> connect(String deviceId) async {
    await _bleManager?.connect(deviceId);
  }

  /// Disconnects from a device by its ID.
  Future<void> disconnect(String deviceId) async {
    await _bleManager?.disconnect(deviceId);
  }

  @override
  void dispose() {
    _bleManager?.dispose();
    super.dispose();
  }
}

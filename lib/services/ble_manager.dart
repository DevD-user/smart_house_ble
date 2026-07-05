import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/smart_device.dart';
import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
import 'mock_ble_service.dart';

/// Manager for handling Bluetooth Low Energy (BLE) operations and stream telemetry.
class BleManager {
  static const String _serviceUuid = '48c5d820-ac2a-11e7-abc4-cec278b6b50a';

  final MockBleService _mockBleService;
  final DeviceProvider _deviceProvider;
  final ConnectionProvider _connectionProvider;
  StreamSubscription? _deviceSubscription;

  BleManager(this._deviceProvider, this._connectionProvider)
    : _mockBleService = MockBleService();

  /// Starts a real BLE scan and listens to the scan results, adding matching devices to the provider.
  void startMockBle() {
    _connectionProvider.startScanning();

    _deviceSubscription?.cancel();
    _deviceSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final device = r.device;
        final localName = r.advertisementData.advName;
        final serviceUuids = r.advertisementData.serviceUuids;

        // Check if device advertises the service UUID or matches the local name 'Simple Peripheral'
        final bool hasServiceUuid = serviceUuids.any((uuid) =>
            uuid.toString().toLowerCase() == _serviceUuid.toLowerCase());
        final bool matchesName = localName.toLowerCase().contains('simple peripheral') ||
            device.platformName.toLowerCase().contains('simple peripheral');

        if (hasServiceUuid || matchesName) {
          final String deviceId = device.remoteId.str;
          final String deviceName = localName.isNotEmpty
              ? localName
              : (device.platformName.isNotEmpty
                  ? device.platformName
                  : 'Simple Peripheral');

          final existingDevice = _deviceProvider.getDevice(deviceId);
          if (existingDevice == null) {
            final newDevice = SmartDevice(
              deviceId: deviceId,
              deviceName: deviceName,
              isConnected: false, // Scanning only, not connected
              lastSeen: DateTime.now(),
              capabilities: {}, // Scanning only, no telemetry yet
            );
            _deviceProvider.addDevice(newDevice);
          } else {
            // Update last seen timestamp
            final updatedDevice = existingDevice.copyWith(
              lastSeen: DateTime.now(),
            );
            _deviceProvider.addDevice(updatedDevice);
          }
        }
      }
    }, onError: (e) {
      _connectionProvider.setError(e.toString());
    });

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    ).catchError((e) {
      _connectionProvider.setError(e.toString());
    });
  }

  /// Stops the real BLE scan and cancels the active stream subscription.
  void stopMockBle() {
    FlutterBluePlus.stopScan().catchError((_) {});
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _connectionProvider.reset();
  }

  /// Disposes of the active stream subscription and underlying mock BLE service resources.
  void dispose() {
    FlutterBluePlus.stopScan().catchError((_) {});
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _mockBleService.dispose();
  }
}

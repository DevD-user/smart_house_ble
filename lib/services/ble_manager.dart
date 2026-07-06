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

  // Multi-device tracking maps
  final Map<String, BluetoothDevice> _activeDevices = {};
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connectionSubscriptions = {};

  BleManager(this._deviceProvider, this._connectionProvider)
    : _mockBleService = MockBleService();

  /// Connects to a device by its ID, performs service discovery, and monitors connection status.
  Future<void> connect(String deviceId) async {
    // 1. Duplicate connection guard
    if (_connectionSubscriptions.containsKey(deviceId)) {
      return;
    }

    // 2. Set connecting state
    _connectionProvider.startConnecting(deviceId: deviceId);

    try {
      final device = BluetoothDevice.fromId(deviceId);
      _activeDevices[deviceId] = device;

      // 3. Subscribe to connection state stream
      final subscription = device.connectionState.listen((state) {
        _handleConnectionStateChange(deviceId, state);
      }, onError: (e) {
        _connectionProvider.setError(e.toString(), deviceId: deviceId);
      });
      _connectionSubscriptions[deviceId] = subscription;

      // 4. Establish GATT connection
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );
    } catch (e) {
      _connectionProvider.setError(e.toString(), deviceId: deviceId);
      _activeDevices.remove(deviceId);
      _connectionSubscriptions[deviceId]?.cancel();
      _connectionSubscriptions.remove(deviceId);
    }
  }

  /// Disconnects from a device and cleans up its subscriptions and active tracking entries.
  Future<void> disconnect(String deviceId) async {
    final device = _activeDevices[deviceId];

    // Cancel the subscription first to prevent unexpected disconnection callback from triggering
    final subscription = _connectionSubscriptions.remove(deviceId);
    if (subscription != null) {
      await subscription.cancel();
    }

    _activeDevices.remove(deviceId);

    if (device != null) {
      try {
        await device.disconnect();
      } catch (_) {
        // Ignore errors during manual disconnect
      }
    }

    // Update connection provider state
    _connectionProvider.setDeviceConnectionState(
      deviceId,
      BleConnectionState.idle,
    );

    // Update device provider state
    _deviceProvider.markDeviceDisconnected(deviceId);
  }

  void _handleConnectionStateChange(String deviceId, BluetoothConnectionState state) {
    if (state == BluetoothConnectionState.connected) {
      _discoverAndVerifyServices(deviceId);
    } else if (state == BluetoothConnectionState.disconnected) {
      _handleUnexpectedDisconnection(deviceId);
    }
  }

  Future<void> _discoverAndVerifyServices(String deviceId) async {
    final device = _activeDevices[deviceId];
    if (device == null) return;

    try {
      final services = await device.discoverServices();
      final hasService = services.any((s) =>
          s.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase());

      if (hasService) {
        // Update connection provider state
        _connectionProvider.setConnected(
          _connectionProvider.connectedDeviceCount + 1,
          deviceId: deviceId,
        );

        // Update device provider state
        final existingDevice = _deviceProvider.getDevice(deviceId);
        if (existingDevice != null) {
          _deviceProvider.addDevice(
            existingDevice.copyWith(isConnected: true),
          );
        }
      } else {
        // Required service is missing, disconnect
        _connectionProvider.setError(
          'Required PotLed service not found',
          deviceId: deviceId,
        );
        await disconnect(deviceId);
      }
    } catch (e) {
      _connectionProvider.setError(e.toString(), deviceId: deviceId);
      await disconnect(deviceId);
    }
  }

  void _handleUnexpectedDisconnection(String deviceId) {
    final subscription = _connectionSubscriptions.remove(deviceId);
    subscription?.cancel();
    _activeDevices.remove(deviceId);

    // Update connection provider state
    _connectionProvider.setDeviceConnectionState(
      deviceId,
      BleConnectionState.idle,
    );

    // Update device provider state
    _deviceProvider.markDeviceDisconnected(deviceId);
  }

  /// Starts a real BLE scan and listens to the scan results, adding matching devices to the provider.
  void startMockBle() {
    _connectionProvider.startScanning();

    _deviceSubscription?.cancel();
    _deviceSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        for (final r in results) {
          final device = r.device;
          final localName = r.advertisementData.advName;
          final serviceUuids = r.advertisementData.serviceUuids;

          // Check if device advertises the service UUID (128-bit or 16-bit FFF0 format)
          final bool hasServiceUuid = serviceUuids.any((uuid) {
            final String uuidStr = uuid.toString().toLowerCase();
            return uuidStr == _serviceUuid.toLowerCase() ||
                uuidStr == 'fff0' ||
                uuidStr.contains('fff0');
          });

          // Check if matches name 'Simple Peripheral' or 'SimplePeripheral' (case-insensitive, ignoring whitespace)
          final String normalizedLocal = localName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
          final String normalizedPlatform = device.platformName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
          final bool matchesName =
              normalizedLocal.contains('simpleperipheral') ||
              normalizedPlatform.contains('simpleperipheral');

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
      },
      onError: (e) {
        _connectionProvider.setError(e.toString());
      },
    );

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15)).catchError((
      e,
    ) {
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

    // Disconnect and clean up all active devices
    final deviceIds = _activeDevices.keys.toList();
    for (final deviceId in deviceIds) {
      disconnect(deviceId).catchError((_) {});
    }

    _mockBleService.dispose();
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/ble/payload_parser.dart';
import '../../services/ble_manager.dart';
import '../connection/connection_provider.dart';
import '../device/device_provider.dart';

/// Provider that wraps and exposes BLE manager control operations.
class BleManagerProvider extends ChangeNotifier {
  BleManager? _bleManager;
  ConnectionProvider? _connectionProvider;
  DeviceProvider? _deviceProvider;
  VoidCallback? _deviceProviderListener;

  /// Exposes the telemetry stream from BleManager
  Stream<TelemetryReading>? get telemetryStream => _bleManager?.telemetryStream;

  /// Exposes the connection events stream from BleManager
  Stream<String>? get connectionEventsStream => _bleManager?.connectionEventsStream;

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

    // Registry Forget Listener & Hygiene
    if (_deviceProvider != deviceProvider) {
      if (_deviceProvider != null && _deviceProviderListener != null) {
        _deviceProvider!.removeListener(_deviceProviderListener!);
      }
      _deviceProvider = deviceProvider;
      _deviceProviderListener = () {
        final activeKnownIds = deviceProvider.devices.keys.toSet();
        final cachedDeviceIds = _bleManager?.cachedDeviceIds.toList() ?? [];
        for (final id in cachedDeviceIds) {
          if (!activeKnownIds.contains(id)) {
            _bleManager?.clearActuatorCache(id);
          }
        }
      };
      _deviceProvider!.addListener(_deviceProviderListener!);
    }
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

  /// Asynchronously requests the version-appropriate BLE/location permissions on Android.
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 31) {
        // Android 12+ (API 31+): Request Bluetooth Scan & Connect
        final scanGranted = await Permission.bluetoothScan.isGranted;
        final connectGranted = await Permission.bluetoothConnect.isGranted;
        if (scanGranted && connectGranted) {
          return true;
        }

        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();

        return (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
               (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
      } else {
        // Android 11 & below (API 30-): Request Location permission
        final locationGranted = await Permission.location.isGranted;
        if (locationGranted) {
          return true;
        }

        final status = await Permission.location.request();
        return status.isGranted;
      }
    }
    return true; // Other platforms handle permissions implicitly or via Info.plist
  }

  /// Starts the mock BLE simulation.
  Future<void> startSimulation() async {
    final granted = await _requestPermissions();
    if (!granted) {
      _connectionProvider?.setError("Bluetooth permissions not granted.");
      return;
    }

    final isBluetoothOn = _bleManager?.isBluetoothOn ?? false;
    if (!isBluetoothOn) {
      _connectionProvider?.setError("Bluetooth is turned off.");
      return;
    }

    _bleManager?.startMockBle();
  }

  /// Stops the mock BLE simulation.
  void stopSimulation() {
    _bleManager?.stopMockBle();
  }

  /// Connects to a device by its ID.
  Future<void> connect(String deviceId) async {
    final granted = await _requestPermissions();
    if (!granted) {
      _connectionProvider?.setError(
        "Bluetooth permissions not granted.",
        deviceId: deviceId,
      );
      return;
    }

    final isBluetoothOn = _bleManager?.isBluetoothOn ?? false;
    if (!isBluetoothOn) {
      _connectionProvider?.setError(
        "Bluetooth is turned off.",
        deviceId: deviceId,
      );
      return;
    }

    await _bleManager?.connect(deviceId);
  }

  /// Disconnects from a device by its ID.
  Future<void> disconnect(String deviceId) async {
    await _bleManager?.disconnect(deviceId);
  }

  /// Writes the LED state to the selected device.
  Future<void> writeLedState(String deviceId, int peripheralId, bool turnOn) async {
    final ble = _bleManager;
    if (ble == null) {
      throw StateError('BleManager is not initialized');
    }
    await ble.writeLedState(deviceId, peripheralId, turnOn);
    notifyListeners();
  }

  /// Retrieves the cached state of an actuator, defaulting to CachedActuatorState.unknown.
  CachedActuatorState getActuatorState(String deviceId, int peripheralId) {
    return _bleManager?.getActuatorState(deviceId, peripheralId) ?? CachedActuatorState.unknown;
  }

  /// Clears the cached actuator state for a specific device.
  void clearActuatorCache(String deviceId) {
    _bleManager?.clearActuatorCache(deviceId);
  }

  @override
  void dispose() {
    if (_deviceProvider != null && _deviceProviderListener != null) {
      _deviceProvider!.removeListener(_deviceProviderListener!);
    }
    _bleManager?.dispose();
    super.dispose();
  }
}

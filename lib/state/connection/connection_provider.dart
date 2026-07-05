import 'package:flutter/material.dart';

/// Represents the connection states for Bluetooth Low Energy (BLE).
enum BleConnectionState {
  idle,
  scanning,
  connecting,
  connected,
  reconnecting,
  error,
}

/// State management provider for tracking and managing the BLE connection state.
class ConnectionProvider extends ChangeNotifier {
  final Map<String, BleConnectionState> _deviceStates = {};
  bool _isBluetoothEnabled = false;
  String? _lastError;
  bool _isScanning = false;

  /// Gets the legacy connection state.
  /// Preserves the existing legacy connectionState behavior only when exactly one tracked device exists.
  /// Returns `BleConnectionState.scanning` if scanning, otherwise returns `idle` if no or multiple devices exist.
  BleConnectionState get connectionState {
    if (_isScanning) {
      return BleConnectionState.scanning;
    }
    if (_deviceStates.length == 1) {
      return _deviceStates.values.first;
    }
    return BleConnectionState.idle;
  }

  /// Gets whether Bluetooth is currently enabled.
  bool get isBluetoothEnabled => _isBluetoothEnabled;

  /// Gets the last recorded error message, if any.
  String? get lastError => _lastError;

  /// Gets the number of connected devices.
  int get connectedDeviceCount => _deviceStates.values
      .where((s) => s == BleConnectionState.connected)
      .length;

  /// Returns true if at least one device is connected.
  bool get anyDeviceConnected => _deviceStates.values
      .any((s) => s == BleConnectionState.connected);

  /// Gets whether a BLE scan is currently active.
  bool get isScanning => _isScanning;

  /// Gets the connection state for a specific device, defaulting to [BleConnectionState.idle].
  BleConnectionState getDeviceConnectionState(String deviceId) {
    return _deviceStates[deviceId] ?? BleConnectionState.idle;
  }

  /// Sets the connection state for a specific device and notifies listeners.
  void setDeviceConnectionState(String deviceId, BleConnectionState state) {
    _deviceStates[deviceId] = state;
    notifyListeners();
  }

  /// Updates the Bluetooth enabled/disabled state and notifies listeners.
  void setBluetoothState(bool enabled) {
    _isBluetoothEnabled = enabled;
    notifyListeners();
  }

  /// Sets the state to scanning and notifies listeners.
  void startScanning() {
    _isScanning = true;
    notifyListeners();
  }

  /// Sets the state to connecting for a device and notifies listeners.
  void startConnecting({String? deviceId}) {
    _isScanning = false;
    if (deviceId != null) {
      _deviceStates[deviceId] = BleConnectionState.connecting;
    }
    notifyListeners();
  }

  /// Sets the state to connected, and updates device state if provided.
  void setConnected(int deviceCount, {String? deviceId}) {
    _isScanning = false;
    if (deviceId != null) {
      _deviceStates[deviceId] = BleConnectionState.connected;
    } else {
      // Backward compatibility: mark first device or a default one as connected
      if (_deviceStates.isEmpty) {
        _deviceStates['default_device'] = BleConnectionState.connected;
      } else {
        final firstKey = _deviceStates.keys.first;
        _deviceStates[firstKey] = BleConnectionState.connected;
      }
    }
    notifyListeners();
  }

  /// Sets the state to reconnecting for a device and notifies listeners.
  void setReconnecting({String? deviceId}) {
    _isScanning = false;
    if (deviceId != null) {
      _deviceStates[deviceId] = BleConnectionState.reconnecting;
    }
    notifyListeners();
  }

  /// Sets the state to error, saves the error message, and optionally sets device state.
  void setError(String message, {String? deviceId}) {
    _lastError = message;
    if (deviceId != null) {
      _deviceStates[deviceId] = BleConnectionState.error;
    }
    notifyListeners();
  }

  /// Resets the provider back to its default idle state and notifies listeners.
  void reset() {
    _deviceStates.clear();
    _isScanning = false;
    _lastError = null;
    notifyListeners();
  }
}

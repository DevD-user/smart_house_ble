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
  BleConnectionState _connectionState = BleConnectionState.idle;
  bool _isBluetoothEnabled = false;
  String? _lastError;
  int _connectedDeviceCount = 0;

  /// Gets the current connection state.
  BleConnectionState get connectionState => _connectionState;

  /// Gets whether Bluetooth is currently enabled.
  bool get isBluetoothEnabled => _isBluetoothEnabled;

  /// Gets the last recorded error message, if any.
  String? get lastError => _lastError;

  /// Gets the number of connected devices.
  int get connectedDeviceCount => _connectedDeviceCount;

  /// Updates the Bluetooth enabled/disabled state and notifies listeners.
  void setBluetoothState(bool enabled) {
    _isBluetoothEnabled = enabled;
    notifyListeners();
  }

  /// Sets the state to scanning and notifies listeners.
  void startScanning() {
    _connectionState = BleConnectionState.scanning;
    notifyListeners();
  }

  /// Sets the state to connecting and notifies listeners.
  void startConnecting() {
    _connectionState = BleConnectionState.connecting;
    notifyListeners();
  }

  /// Sets the state to connected, updates the connected device count, and notifies listeners.
  void setConnected(int deviceCount) {
    _connectionState = BleConnectionState.connected;
    _connectedDeviceCount = deviceCount;
    notifyListeners();
  }

  /// Sets the state to reconnecting and notifies listeners.
  void setReconnecting() {
    _connectionState = BleConnectionState.reconnecting;
    notifyListeners();
  }

  /// Sets the state to error, saves the error message, and notifies listeners.
  void setError(String message) {
    _connectionState = BleConnectionState.error;
    _lastError = message;
    notifyListeners();
  }

  /// Resets the provider back to its default idle state and notifies listeners.
  void reset() {
    _connectionState = BleConnectionState.idle;
    _connectedDeviceCount = 0;
    _lastError = null;
    notifyListeners();
  }
}

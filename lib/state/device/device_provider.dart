import 'package:flutter/material.dart';
import '../../models/smart_device.dart';

/// State management provider for handling smart devices in the BLE ecosystem.
class DeviceProvider extends ChangeNotifier {
  final Map<String, SmartDevice> _devices = {};

  /// Exposes a read-only map of registered devices.
  Map<String, SmartDevice> get devices => Map.unmodifiable(_devices);

  /// Registers a new device or updates an existing device in the provider.
  void addDevice(SmartDevice device) {
    _devices[device.deviceId] = device;
    notifyListeners();
  }

  /// Removes a device from the provider.
  void removeDevice(String deviceId) {
    if (_devices.containsKey(deviceId)) {
      _devices.remove(deviceId);
      notifyListeners();
    }
  }

  /// Retrieves a device by its ID, if it exists.
  SmartDevice? getDevice(String deviceId) {
    return _devices[deviceId];
  }

  /// Updates a specific capability value for a device and notifies listeners.
  void updateDeviceCapability(String deviceId, int capabilityId, dynamic value) {
    final device = _devices[deviceId];
    if (device != null) {
      device.updateCapability(capabilityId, value);
      notifyListeners();
    }
  }

  /// Marks a device as disconnected and notifies listeners.
  void markDeviceDisconnected(String deviceId) {
    final device = _devices[deviceId];
    if (device != null) {
      device.markDisconnected();
      notifyListeners();
    }
  }

  /// Clears all devices from the provider.
  void clearDevices() {
    _devices.clear();
    notifyListeners();
  }
}

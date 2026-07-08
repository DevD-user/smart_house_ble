import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/smart_device.dart';
import '../../storage/device_storage.dart';

/// State management provider for handling smart devices in the BLE ecosystem.
class DeviceProvider extends ChangeNotifier {
  final Map<String, SmartDevice> _devices = {};
  final Map<String, String> _aliases = {};
  final Map<String, String> _advertisedNames = {};
  final Set<String> _knownDeviceIds = {};

  DeviceProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final loaded = await DeviceStorage.getAliases();
    _aliases.addAll(loaded);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('known_devices');
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final deviceMap = Map<String, dynamic>.from(value as Map);
          final device = SmartDevice.fromMap(deviceMap);
          // Force isConnected to false on startup
          _devices[key] = device.copyWith(isConnected: false);
          _advertisedNames[key] = device.deviceName;
          _knownDeviceIds.add(key);
        });
      }
    } catch (_) {
      // Safely ignore load errors
    }

    // Apply aliases to any devices already registered
    for (final entry in _devices.entries) {
      final alias = _aliases[entry.key];
      if (alias != null) {
        _devices[entry.key] = entry.value.copyWith(deviceName: alias);
      }
    }
    notifyListeners();
  }

  Future<void> _saveKnownDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> serialized = {};
      for (final deviceId in _knownDeviceIds) {
        final device = _devices[deviceId];
        if (device != null) {
          // Force isConnected to false when persisting
          final persistedDevice = device.copyWith(isConnected: false);
          serialized[deviceId] = persistedDevice.toMap();
        }
      }
      await prefs.setString('known_devices', json.encode(serialized));
    } catch (_) {
      // Safely ignore write errors
    }
  }

  /// Exposes a read-only map of registered devices.
  Map<String, SmartDevice> get devices => Map.unmodifiable(_devices);

  /// Registers a new device or updates an existing device in the provider.
  void addDevice(SmartDevice device) {
    // Preserve the original advertised name
    _advertisedNames[device.deviceId] = device.deviceName;

    final alias = _aliases[device.deviceId];
    if (alias != null) {
      _devices[device.deviceId] = device.copyWith(deviceName: alias);
    } else {
      _devices[device.deviceId] = device;
    }

    // A device becomes known when it is connected.
    if (device.isConnected && !_knownDeviceIds.contains(device.deviceId)) {
      _knownDeviceIds.add(device.deviceId);
      _saveKnownDevices();
    }

    notifyListeners();
  }

  /// Sets or updates a custom alias for a device.
  Future<void> setDeviceAlias(String deviceId, String alias) async {
    if (alias.trim().isEmpty) {
      // Revert to original advertised name if name is set to empty
      _aliases.remove(deviceId);
      await DeviceStorage.removeAlias(deviceId);
      final originalName = _advertisedNames[deviceId];
      final device = _devices[deviceId];
      if (device != null && originalName != null) {
        _devices[deviceId] = device.copyWith(deviceName: originalName);
      }
    } else {
      _aliases[deviceId] = alias;
      await DeviceStorage.saveAlias(deviceId, alias);
      final device = _devices[deviceId];
      if (device != null) {
        _devices[deviceId] = device.copyWith(deviceName: alias);
      }
      _knownDeviceIds.add(deviceId);
    }
    await _saveKnownDevices();
    notifyListeners();
  }

  /// Removes the device configuration (alias and device list tracking) from the provider.
  Future<void> forgetDevice(String deviceId) async {
    _aliases.remove(deviceId);
    await DeviceStorage.removeAlias(deviceId);

    // Revert active device name to its original in memory
    final originalName = _advertisedNames[deviceId];
    final device = _devices[deviceId];
    if (device != null && originalName != null) {
      _devices[deviceId] = device.copyWith(deviceName: originalName);
    }

    _knownDeviceIds.remove(deviceId);
    await _saveKnownDevices();

    removeDevice(deviceId);
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

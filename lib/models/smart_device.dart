import 'capability_types.dart';
import 'device_capability.dart';

/// Represents a smart device connected via BLE in the smart home ecosystem.
class SmartDevice {
  final String deviceId;
  final String deviceName;
  bool isConnected;
  DateTime lastSeen;
  final Map<int, DeviceCapability> capabilities;

  /// Creates a [SmartDevice] instance with all required fields.
  SmartDevice({
    required this.deviceId,
    required this.deviceName,
    required this.isConnected,
    required this.lastSeen,
    required this.capabilities,
  });

  /// Creates a copy of this [SmartDevice] with the given fields replaced with new values.
  SmartDevice copyWith({
    String? deviceId,
    String? deviceName,
    bool? isConnected,
    DateTime? lastSeen,
    Map<int, DeviceCapability>? capabilities,
  }) {
    return SmartDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      isConnected: isConnected ?? this.isConnected,
      lastSeen: lastSeen ?? this.lastSeen,
      capabilities: capabilities ?? Map<int, DeviceCapability>.from(this.capabilities),
    );
  }

  /// Converts this [SmartDevice] instance into a [Map].
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'isConnected': isConnected,
      'lastSeen': lastSeen.toIso8601String(),
      'capabilities': capabilities.map((key, value) => MapEntry(key.toString(), value.toMap())),
    };
  }

  /// Creates a [SmartDevice] instance from a [Map].
  factory SmartDevice.fromMap(Map<String, dynamic> map) {
    final rawCapabilities = map['capabilities'] as Map<dynamic, dynamic>? ?? const {};
    final parsedCapabilities = <int, DeviceCapability>{};
    rawCapabilities.forEach((key, value) {
      final intKey = int.parse(key.toString());
      final capMap = Map<String, dynamic>.from(value as Map);
      parsedCapabilities[intKey] = DeviceCapability.fromMap(capMap);
    });

    return SmartDevice(
      deviceId: map['deviceId'] as String,
      deviceName: map['deviceName'] as String,
      isConnected: map['isConnected'] as bool? ?? false,
      lastSeen: DateTime.parse(map['lastSeen'] as String),
      capabilities: parsedCapabilities,
    );
  }

  /// Adds a capability to this device, mapping it by its capability type ID.
  void addCapability(DeviceCapability capability) {
    capabilities[capability.capabilityType.id] = capability;
  }

  /// Locates a capability by its ID and updates its value.
  void updateCapability(int capabilityId, dynamic value) {
    final capability = capabilities[capabilityId];
    if (capability != null) {
      capability.updateValue(value);
    }
  }

  /// Marks the device as connected and updates the last seen timestamp to now.
  void markConnected() {
    isConnected = true;
    lastSeen = DateTime.now();
  }

  /// Marks the device as disconnected.
  void markDisconnected() {
    isConnected = false;
  }
}

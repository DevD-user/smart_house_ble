import 'capability_types.dart';

/// Represents a capability of a smart device within the BLE smart home ecosystem.
class DeviceCapability {
  final CapabilityType capabilityType;
  dynamic currentValue;
  DateTime lastUpdated;
  final bool isAvailable;
  final String? unit;

  /// Creates a [DeviceCapability] instance with all fields.
  DeviceCapability({
    required this.capabilityType,
    required this.currentValue,
    required this.lastUpdated,
    required this.isAvailable,
    required this.unit,
  });

  /// Creates a copy of this [DeviceCapability] with the given fields replaced with new values.
  DeviceCapability copyWith({
    CapabilityType? capabilityType,
    dynamic currentValue,
    DateTime? lastUpdated,
    bool? isAvailable,
    String? unit,
    bool nullifyUnit = false,
  }) {
    return DeviceCapability(
      capabilityType: capabilityType ?? this.capabilityType,
      currentValue: currentValue ?? this.currentValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isAvailable: isAvailable ?? this.isAvailable,
      unit: nullifyUnit ? null : (unit ?? this.unit),
    );
  }

  /// Converts this [DeviceCapability] instance into a [Map].
  Map<String, dynamic> toMap() {
    return {
      'capabilityType': capabilityType.name,
      'currentValue': currentValue,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isAvailable': isAvailable,
      'unit': unit,
    };
  }

  /// Creates a [DeviceCapability] instance from a [Map].
  factory DeviceCapability.fromMap(Map<String, dynamic> map) {
    final capabilityTypeName = map['capabilityType'] as String;
    final type = CapabilityType.values.firstWhere(
      (e) => e.name == capabilityTypeName,
      orElse: () => throw ArgumentError('Unknown CapabilityType: $capabilityTypeName'),
    );

    return DeviceCapability(
      capabilityType: type,
      currentValue: map['currentValue'],
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      isAvailable: map['isAvailable'] as bool? ?? false,
      unit: map['unit'] as String?,
    );
  }

  /// Updates the [currentValue] and automatically updates [lastUpdated] to the current time.
  void updateValue(dynamic newValue) {
    currentValue = newValue;
    lastUpdated = DateTime.now();
  }
}

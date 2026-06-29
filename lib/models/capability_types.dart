enum CapabilityType { voltage, touch, battery, temperature, rgbLed, relay }

extension CapabilityTypeExtension on CapabilityType {
  /// Returns the user-friendly display name for the capability type.
  String get displayName {
    return switch (this) {
      CapabilityType.voltage => 'Voltage Sensor',
      CapabilityType.touch => 'Touch Sensor',
      CapabilityType.battery => 'Battery',
      CapabilityType.temperature => 'Temperature Sensor',
      CapabilityType.rgbLed => 'RGB LED',
      CapabilityType.relay => 'Relay',
    };
  }

  /// Returns the unique ID associated with the capability type.
  int get id {
    return switch (this) {
      CapabilityType.voltage => 1,
      CapabilityType.touch => 2,
      CapabilityType.battery => 3,
      CapabilityType.temperature => 4,
      CapabilityType.rgbLed => 5,
      CapabilityType.relay => 6,
    };
  }
}

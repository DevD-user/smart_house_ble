import 'package:flutter/material.dart';

import '../models/capability_types.dart';
import '../models/smart_device.dart';

/// A card widget displaying a summary of a smart device's status and telemetry.
class DeviceCard extends StatelessWidget {
  final SmartDevice device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final voltageCapability = device.capabilities[CapabilityType.voltage.id];

    final batteryCapability = device.capabilities[CapabilityType.battery.id];

    final voltageText = voltageCapability != null
        ? '${voltageCapability.currentValue} V'
        : '-- V';

    final batteryText = batteryCapability != null
        ? '${batteryCapability.currentValue} %'
        : '-- %';

    final statusColor = device.isConnected
        ? Colors.green
        : theme.colorScheme.error;
    final statusText = device.isConnected ? 'Online' : 'Disconnected';

    // Future support: Sleeping state for low-power BLE devices

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Device Name
              Text(
                device.deviceName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 2. Device Status Logic
              Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Voltage Text
              Text('Voltage: $voltageText', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),

              // 4. Battery Text
              Text('Battery: $batteryText', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

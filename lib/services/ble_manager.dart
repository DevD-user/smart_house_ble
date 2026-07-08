import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/smart_device.dart';
import '../state/connection/connection_provider.dart';
import '../state/device/device_provider.dart';
import 'ble/payload_parser.dart';
import 'mock_ble_service.dart';

/// Represents the application's cached state of an actuator.
enum CachedActuatorState {
  unknown,
  off,
  on,
}

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

  // Instance-level telemetry stream and subscription mapping
  final StreamController<TelemetryReading> _telemetryController =
      StreamController<TelemetryReading>.broadcast();

  Stream<TelemetryReading> get telemetryStream => _telemetryController.stream;

  // Connection events stream (emits deviceId when a new connection is initiated)
  final StreamController<String> _connectionEventsController =
      StreamController<String>.broadcast();

  Stream<String> get connectionEventsStream => _connectionEventsController.stream;

  final Map<String, List<StreamSubscription<List<int>>>> _telemetrySubscriptions = {};

  // Telemetry-producing characteristic mapping (lowercase UUID -> sensorType)
  static const Map<String, String> _telemetryCharacteristics = {
    '48c5d821-ac2a-11e7-abc4-cec278b6b50a': 'voltage',
  };

  // Cached LED write characteristics (deviceId -> characteristic)
  final Map<String, BluetoothCharacteristic> _ledCharacteristics = {};

  // Session-scoped actuator cache: deviceId -> (peripheralId -> state)
  final Map<String, Map<int, CachedActuatorState>> _actuatorCache = {};

  // LED control characteristic UUID constant
  static const String _ledCharUuid = '48c5d822-ac2a-11e7-abc4-cec278b6b50a';

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  BluetoothAdapterState _currentAdapterState = BluetoothAdapterState.unknown;
  bool _isScanning = false;

  BleManager(this._deviceProvider, this._connectionProvider)
    : _mockBleService = MockBleService() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _currentAdapterState = state;
      _handleAdapterStateChange(state);
    });
  }

  /// Connects to a device by its ID, performs service discovery, and monitors connection status.
  Future<void> connect(String deviceId) async {
    // 1. Duplicate connection guard
    if (_connectionSubscriptions.containsKey(deviceId)) {
      return;
    }

    // Emit event that a new connection is initiated to clear old telemetry session
    _connectionEventsController.add(deviceId);

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

    // Clean up telemetry subscriptions for this device
    final telemetrySubs = _telemetrySubscriptions.remove(deviceId);
    if (telemetrySubs != null) {
      for (final sub in telemetrySubs) {
        await sub.cancel();
      }
    }

    _ledCharacteristics.remove(deviceId);
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

  /// Returns whether Bluetooth is currently turned on.
  bool get isBluetoothOn => _currentAdapterState == BluetoothAdapterState.on;

  void _handleAdapterStateChange(BluetoothAdapterState state) {
    final bool isEnabled = state == BluetoothAdapterState.on;
    _connectionProvider.setBluetoothState(isEnabled);

    if (state == BluetoothAdapterState.unauthorized) {
      _connectionProvider.setError("Bluetooth permissions not granted.");
    }

    if (!isEnabled) {
      // 1. Stop scanning if active
      if (_connectionProvider.isScanning) {
        stopMockBle();
      }

      // 2. Disconnect active devices and reset their states
      final deviceIds = _activeDevices.keys.toList();
      for (final deviceId in deviceIds) {
        disconnect(deviceId).catchError((_) {});
      }
    }
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

        // Clean up any stale telemetry subscriptions first
        final oldSubs = _telemetrySubscriptions.remove(deviceId);
        if (oldSubs != null) {
          for (final sub in oldSubs) {
            await sub.cancel();
          }
        }

        // Setup subscriptions for discovered telemetry characteristics
        final List<StreamSubscription<List<int>>> subs = [];
        for (final service in services) {
          for (final characteristic in service.characteristics) {
            final uuidStr = characteristic.uuid.toString().toLowerCase();

            // Cache the LED write characteristic if found
            if (uuidStr == _ledCharUuid.toLowerCase()) {
              _ledCharacteristics[deviceId] = characteristic;
            }

            final sensorType = _telemetryCharacteristics[uuidStr];
            final props = characteristic.properties;

            if (sensorType != null && (props.notify || props.indicate)) {
              await characteristic.setNotifyValue(true);
              final sub = characteristic.onValueReceived.listen((bytes) {
                try {
                  final reading = PayloadParser.parse(
                    deviceId: deviceId,
                    sensorType: sensorType,
                    bytes: bytes,
                  );
                  _telemetryController.add(reading);
                } catch (_) {
                  // Ignore parsing errors or handle gracefully
                }
              });
              subs.add(sub);
            }
          }
        }

        if (subs.isNotEmpty) {
          _telemetrySubscriptions[deviceId] = subs;
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

    // Clean up telemetry subscriptions for this device
    final telemetrySubs = _telemetrySubscriptions.remove(deviceId);
    if (telemetrySubs != null) {
      for (final sub in telemetrySubs) {
        sub.cancel();
      }
    }

    _ledCharacteristics.remove(deviceId);
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
    _isScanning = true;
    _connectionProvider.startScanning();

    _deviceSubscription?.cancel();
    _deviceSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        if (!_isScanning) return;
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
    _isScanning = false;
    FlutterBluePlus.stopScan().catchError((_) {});
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _connectionProvider.reset();
  }

  /// Disposes of the active stream subscription and underlying mock BLE service resources.
  void dispose() {
    _isScanning = false;
    FlutterBluePlus.stopScan().catchError((_) {});
    _deviceSubscription?.cancel();
    _deviceSubscription = null;
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;

    // Disconnect and clean up all active devices
    final deviceIds = _activeDevices.keys.toList();
    for (final deviceId in deviceIds) {
      disconnect(deviceId).catchError((_) {});
    }

    // Cancel telemetry subscriptions
    for (final subs in _telemetrySubscriptions.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }
    _telemetrySubscriptions.clear();
    _ledCharacteristics.clear();

    // Close the telemetry controller stream
    _telemetryController.close();

    // Close the connection events controller stream
    _connectionEventsController.close();

    _mockBleService.dispose();
  }

  /// Writes a state value to the LED characteristic of the selected device.
  /// Returns a Future that completes when the write operation succeeds.
  Future<void> writeLedState(String deviceId, int peripheralId, bool turnOn) async {
    final characteristic = _ledCharacteristics[deviceId];
    if (characteristic == null) {
      throw StateError('LED write characteristic not available or device not connected');
    }
    final payload = [peripheralId, turnOn ? 0x01 : 0x00];
    await characteristic.write(payload, withoutResponse: false);

    // Update the actuator cache only after a successful write completes
    final deviceCache = _actuatorCache.putIfAbsent(deviceId, () => {});
    deviceCache[peripheralId] = turnOn ? CachedActuatorState.on : CachedActuatorState.off;
  }

  /// Retrieves the cached state of an actuator, defaulting to CachedActuatorState.unknown.
  CachedActuatorState getActuatorState(String deviceId, int peripheralId) {
    return _actuatorCache[deviceId]?[peripheralId] ?? CachedActuatorState.unknown;
  }

  /// Clears the cached actuator state for a specific device.
  void clearActuatorCache(String deviceId) {
    _actuatorCache.remove(deviceId);
  }

  /// Exposes the list of devices in the actuator cache.
  Iterable<String> get cachedDeviceIds => _actuatorCache.keys;
}

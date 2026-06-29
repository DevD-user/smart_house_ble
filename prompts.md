# Smart House BLE - Prompts Log

This file tracks the history of prompts given in this workspace for tracking progress, backtracking, and documentation.

---

## Prompt 1
**Date/Time:** 2026-06-29 20:22:16 (GMT+5:30)
**Status:** Executed (Implemented in lib/state/connection/connection_provider.dart via Prompt 5)
**Content:**
```text
do not execute this step yet. just tell me if u have done all this or is this the first time i am telling u this 
Create a Dart file called connection_provider.dart

Location:
lib/state/connection/connection_provider.dart

Requirements:

1. Import flutter/material.dart

2. Create enum called BleConnectionState

Values:

idle

scanning

connecting

connected

reconnecting

error

3. Create class ConnectionProvider extending ChangeNotifier.

4. Private fields:

BleConnectionState _connectionState = BleConnectionState.idle

bool _isBluetoothEnabled = false

String? _lastError

int _connectedDeviceCount = 0

5. Public getters for all fields.

6. Create method:

void setBluetoothState(bool enabled)

- update bluetooth state

- notifyListeners()

7. Create method:

void startScanning()

- set state = scanning

- notifyListeners()

8. Create method:

void startConnecting()

- set state = connecting

- notifyListeners()

9. Create method:

void setConnected(int deviceCount)

- set state = connected

- update connected device count

- notifyListeners()

10. Create method:

void setReconnecting()

- set state = reconnecting

- notifyListeners()

11. Create method:

void setError(String message)

- set state = error

- save error message

- notifyListeners()

12. Create method:

void reset()

- state = idle

- connected device count = 0

- clear error

- notifyListeners()

13. No UI code.

14. No other files.

15. Clean production-style scalable architecture only.
```

---

## Prompt 2
**Date/Time:** 2026-06-29 20:23:47 (GMT+5:30)
**Status:** Answered (Investigated and confirmed no prior records of this request exist)
**Content:**
```text
not current. have i told u this before either ?
```

---

## Prompt 3
**Date/Time:** 2026-06-29 20:29:15 (GMT+5:30)
**Status:** Executed (Setup prompts log)
**Content:**
```text
okay do one more thing from now on. every prompt that i give u, i want u to write it all in one prompts.md file and label them in order as well. this will help me know what i have given u to do and allow backracking or know what has been done so far. also tell me what prompt did u execute before ?
```

---

## Prompt 4
**Date/Time:** 2026-06-29 20:31:09 (GMT+5:30)
**Status:** Executed (Recreated prompts log with date/time stamps)
**Content:**
```text
hey i accidentally rejected the change. make the prompt file again and also when u document the prompts, add date and time to each as well
```

---

## Prompt 5
**Date/Time:** 2026-06-29 20:40:35 (GMT+5:30)
**Status:** Executed (Created connection_provider.dart)
**Content:**
```text
Create a Dart file called connection_provider.dart

Location:
lib/state/connection/connection_provider.dart

Requirements:

1. Import flutter/material.dart

2. Create enum called BleConnectionState

Values:

idle

scanning

connecting

connected

reconnecting

error

3. Create class ConnectionProvider extending ChangeNotifier.

4. Private fields:

BleConnectionState _connectionState = BleConnectionState.idle

bool _isBluetoothEnabled = false

String? _lastError

int _connectedDeviceCount = 0

5. Public getters for all fields.

6. Create method:

void setBluetoothState(bool enabled)

- update bluetooth state

- call notifyListeners()

7. Create method:

void startScanning()

- set state = scanning

- call notifyListeners()

8. Create method:

void startConnecting()

- set state = connecting

- call notifyListeners()

9. Create method:

void setConnected(int deviceCount)

- set state = connected

- update connected device count

- call notifyListeners()

10. Create method:

void setReconnecting()

- set state = reconnecting

- call notifyListeners()

11. Create method:

void setError(String message)

- set state = error

- save error message

- call notifyListeners()

12. Create method:

void reset()

- state = idle

- connected device count = 0

- clear error

- notifyListeners()

13. No UI code.

14. No other files.

15. Clean production-style scalable architecture only.
```

---

## Prompt 6
**Date/Time:** 2026-06-29 20:44:46 (GMT+5:30)
**Status:** Executed (Created theme_provider.dart)
**Content:**
```text
Create a Dart file called theme_provider.dart

Location:
lib/state/theme/theme_provider.dart

Requirements:

1. Import flutter/material.dart

2. Create enum AppThemeMode

Values:

light

dark

3. Create class ThemeProvider extending ChangeNotifier.

4. Private field:

AppThemeMode _currentTheme = AppThemeMode.dark

5. Public getter:

AppThemeMode get currentTheme

6. Public getter:

bool get isDarkMode

Should return true if current theme is dark.

7. Create method:

void toggleTheme()

- switch between dark and light mode

- call notifyListeners()

8. Create method:

void setDarkMode()

- set theme = dark

- call notifyListeners()

9. Create method:

void setLightMode()

- set theme = light

- call notifyListeners()

10. Create method:

void resetTheme()

- set default theme = dark

- call notifyListeners()

11. No UI code.

12. No other files.

13. Clean production-style scalable architecture only.
```

---

## Prompt 7
**Date/Time:** 2026-06-29 20:53:35 (GMT+5:30)
**Status:** Executed (Created mock_ble_service.dart)
**Content:**
```text
Create a Dart file called mock_ble_service.dart

Location:
lib/services/mock_ble_service.dart

Requirements:

1. Import dart:async

2. Import dart:math

3. Create class MockBleService

4. Private field:

Timer? _mockTimer

5. Create StreamController<Map<String, dynamic>>

Private field:

final StreamController<Map<String, dynamic>> _deviceStreamController =
    StreamController.broadcast();

6. Public getter:

Stream<Map<String, dynamic>> get deviceStream

7. Create method:

void startMockStreaming()

Behavior:

Every 2 seconds generate fake data for two devices.

Device A:

deviceId = Node_A

Random voltage between 1.5 and 3.3

Battery between 60 and 100

Device B:

deviceId = Node_B

Random voltage between 1.0 and 3.3

Battery between 50 and 100

Emit both devices separately through stream.

Example emitted map:

{
  "deviceId": "Node_A",
  "sensorId": 1,
  "value": 2.31,
  "battery": 82
}

8. Create method:

void stopMockStreaming()

- stop timer

9. Create method:

void dispose()

- cancel timer

- close stream controller

10. No UI code.

11. No BLE package usage.

12. No other files.

13. Clean production-style scalable architecture only.
```

---

## Prompt 8
**Date/Time:** 2026-06-29 21:14:21 (GMT+5:30)
**Status:** Executed (Created ble_manager.dart)
**Content:**
```text
Create a Dart file called ble_manager.dart

Location:
lib/services/ble_manager.dart

Requirements:

1. Import dart:async

2. Import mock_ble_service.dart

3. Import smart_device.dart

4. Import device_capability.dart

5. Import capability_types.dart

6. Import device_provider.dart

7. Import connection_provider.dart

8. Create class BleManager

9. Private fields:

final MockBleService _mockBleService

final DeviceProvider _deviceProvider

final ConnectionProvider _connectionProvider

StreamSubscription? _deviceSubscription

10. Constructor must receive:

DeviceProvider

ConnectionProvider

Inside constructor initialize MockBleService.

11. Create method:

void startMockBle()

Behavior:

- call _connectionProvider.startScanning()

- call _mockBleService.startMockStreaming()

- listen to deviceStream

12. On receiving packet:

Read:

deviceId

sensorId

value

13. If device does not exist:

Create SmartDevice

Create DeviceCapability for voltage

Add device to DeviceProvider

14. If device exists:

Update device capability

15. Update connection state using:

_connectionProvider.setConnected()

16. Create method:

void stopMockBle()

- stop mock service

- cancel stream subscription

- reset connection provider

17. Create dispose()

- cancel stream

- dispose mock service

18. No UI code

19. No other files

20. Clean production-style scalable architecture only
```

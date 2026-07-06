# 03 — Technical Architecture

This maps the frozen product architecture (02) onto the existing Flutter codebase.
Existing foundation (Provider, navigation shell, theme system, BLE abstraction) is
preserved and extended — not replaced.

---

## Existing project structure (preserved)

```
lib/
- main.dart
- screens/
  - splash_screen.dart
  - navigation_wrapper.dart
  - home_page.dart          (to be refactored per 02)
- services/
  - ble_manager.dart
  - mock_ble_service.dart
- state/
  - ble/
    - ble_manager_provider.dart
  - connection/
  - device/
  - theme/
- theme/
  - app_theme.dart
- widgets/
  - (existing reusable widgets)
```

New folders/files to be added sit alongside this structure, not on top of a rewrite.

---

## Layer responsibilities

```
Presentation (screens/, widgets/)
- Home, Devices, Monitor, Control, History, Device Detail
- Reads state via Provider/Consumer, never touches BLE or storage directly

Domain / State (state/)
- Existing providers preserved:
  - BleManagerProvider
  - ConnectionProvider
  - DeviceProvider
  - ThemeProvider
- Extended for multi-device (see below)

Data / Services (services/)
- BleManager (abstraction) — mock now, real BLE later, same interface
- MockBleService — stays until real BLE integration replaces it
- New: local storage services (Hive) for session/history/alerts
- New: parsing utilities for raw BLE payloads (uint16 little-endian etc.)
```

---

## Multi-device BLE architecture (must-have from day one)

The current providers assume a single implicit device. They must be extended to key
all state by device ID, so 1 device today becomes N devices later with no rewrite.

```
BleManagerProvider
- Manages a Map<deviceId, DeviceConnection>
- Each DeviceConnection owns:
  - connection state (disconnected/scanning/connecting/connected/reconnecting/error)
  - notification stream subscription
  - RSSI value
  - last-seen timestamp
- No global "the connected device" — always addressed by deviceId

DeviceProvider
- Registry of known/paired devices (metadata: name, id, firmware version placeholder)
- Independent of live connection state (a device can be "known" but disconnected)

ConnectionProvider
- Thin wrapper/derived state per screen if needed (e.g. "any device connected?" for
  Home's house-health summary)
```

Rule: nothing in the app may assume a single global BLE connection. Every stream,
command, and RSSI read is addressed by device ID.

---

## BLE payload parsing (current, frozen protocol)

```
Characteristic notify -> raw bytes -> parse -> typed value

Example (ADC telemetry):
  bytes received:  0xFA 0x0B
  interpretation:  little-endian uint16
  value:           0x0BFA = 3066

Parsing must live in a single shared utility (services/ble/payload_parser.dart or
similar) — never inline-parsed per screen. This isolates the byte-order/format
knowledge in one place so future protocol changes (JSON/CBOR, more sensors) touch
one file, not every screen.
```

---

## Storage architecture (tiered)

```
Tier 1 — Real-time buffer
- In-memory only, ~20-30 seconds
- Feeds: Device Detail live graph, live gauge
- Not persisted, cleared on disconnect/app restart

Tier 2 — Session history
- ~24 hours retention
- Stores: telemetry readings, connect/disconnect events, command history, RSSI
  changes, warnings
- Implementation: Hive (initial), SQLite as future upgrade path for heavier analytics

Tier 3 — Historical analytics
- 7 days now, 30 days future target
- Stores: historical telemetry, historical alerts, connection stability, signal
  quality trends, uptime stats
- Feeds: Monitor's Compare Mode, History's trends view
```

---

## Alerts architecture (generic, extensible)

```
Alert model (not sensor-specific):
- type (disconnect / timeout / weak-signal / value-out-of-range / command-failed / ...)
- deviceId
- severity
- timestamp
- payload (generic key-value, so future sensors don't require model changes)

V1 behavior: local in-app only
- Warning banners, snackbars, alert cards inside Monitor
- Persisted to Tier 2/3 storage for History screen

Future (not built now, but the model above must not block it):
- V2: background local notifications
- V3: local automation rule engine (condition -> action)
- V4+: cloud-connected push (FCM/MQTT/backend)
```

---

## Data flow (single device, current scope)

```
CC2640R2 board
     │  BLE notify (raw bytes)
     ▼
BleManager (real BLE, replacing mock)
     │  parsed uint16 value, tagged with deviceId
     ▼
BleManagerProvider (per-device stream)
     │  notifyListeners()
     ▼
Device Detail screen (Consumer)
     │
     ├──► Tier 1 buffer (live graph)
     └──► Tier 2/3 storage (Hive) ──► History / Monitor Compare Mode
```

---

## Explicit non-goals for this technical layer (V1)
- No replacement of Provider with Riverpod/Bloc/etc.
- No change to navigation shell (IndexedStack, bottom nav) mechanics.
- No cloud/auth dependency anywhere in this layer.
- No mesh/relay logic between boards.

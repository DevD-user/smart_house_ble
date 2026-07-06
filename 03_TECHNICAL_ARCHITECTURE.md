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
  - devices_page.dart       (built — Phase 1)
  - device_detail_page.dart (placeholder built in Phase 1, real content in Phase 2)
- services/
  - ble_manager.dart
  - mock_ble_service.dart
  - ble/
    - payload_parser.dart   (Phase 2)
- state/
  - ble/
    - ble_manager_provider.dart
  - connection/
  - device/
  - telemetry/
    - telemetry_provider.dart (Phase 2, new)
  - theme/
- storage/
  - device_storage.dart     (built — Phase 1, device aliases)
- theme/
  - app_theme.dart
- widgets/
  - (existing reusable widgets)
```

New folders/files sit alongside this structure, not on top of a rewrite.

---

## Layer responsibilities

```
Presentation (screens/, widgets/)
- Home, Devices, Monitor, Control, History, Device Detail
- Reads state via Provider/Consumer, never touches BLE or storage directly

Domain / State (state/)
- BleManagerProvider   — connect/disconnect/scan orchestration, write-path entry
- ConnectionProvider   — per-device connection state (connecting/connected/error/...)
- DeviceProvider       — device registry only: metadata, alias, paired/known list
- TelemetryProvider    — live sensor readings only, per (deviceId, sensorType)
- ThemeProvider        — unchanged

Data / Services (services/)
- BleManager (abstraction) — real BLE scan/connect/notify/write
- MockBleService — retained for future testing, bypassed for real scan/connect
- payload_parser.dart — raw BLE payload -> typed telemetry reading
- storage/ — local persistence (device aliases now; Hive session/history later)
```

---

## Multi-device BLE architecture (must-have from day one)

All state is keyed by deviceId. No provider anywhere assumes a single implicit
device — this applies to connection state (built, Phase 1) and telemetry state
(Phase 2).

```
BleManagerProvider / ConnectionProvider
- Manages per-device connection state (disconnected/scanning/connecting/
  connected/reconnecting/error), RSSI, last-seen timestamp
- No global "the connected device" — always addressed by deviceId

DeviceProvider
- Registry of known/paired devices: name, alias, deviceId, connection flag
- Independent of live connection state and independent of telemetry
- Does NOT store sensor readings (see TelemetryProvider below)

TelemetryProvider (Phase 2)
- Live sensor data only, never touches BLE internals directly
- Never writes/commands anything to a device (read-path only)
```

Rule: nothing in the app may assume a single global BLE connection or a single
global sensor reading. Every stream, command, RSSI read, and telemetry value is
addressed by deviceId (and sensorType, for telemetry).

---

## GATT service/characteristic discovery

```
- BleManager performs service/characteristic discovery after connect (already
  built in Task 1.4A's service-discovery step).
- Discovered characteristics are stored internally per deviceId — not exposed
  to UI or providers directly.
- UI and providers never access characteristics directly; they only call
  BleManager's higher-level methods (connect, disconnect, write, and the
  notify pipeline feeding TelemetryProvider).
- BleManager uses the stored per-device characteristics for notify
  subscriptions (read path) and write operations (write path).
```

This matters once Board A and Board B expose different capabilities — the
characteristic map is per-device, so one board having a characteristic the
other doesn't causes no ambiguity elsewhere in the app.

---

## TelemetryReading — canonical model (freeze this shape)

```
TelemetryReading
- deviceId
- sensorType
- value
- timestamp
- unit (optional, unused today, reserved for future sensors e.g. "°C", "V")
- quality/status (optional, reserved for future use, e.g. stale/estimated)
```

Every ticket that produces or consumes telemetry readings uses this exact
shape. Extending it later (e.g. adding `unit`'s actual usage) is additive, not
a redesign.

---

## Capability-aware rendering (principle, not built yet)

Device Detail, Monitor, and Control must render dynamically based on the
capabilities discovered for that specific device, rather than assuming every
board exposes the same sensors or actuators. This is a rendering principle for
when Board A and Board B differ — it does not require building a capability-
detection system now. The per-device characteristic map (above) is what will
eventually drive this; the UI-side dynamic rendering is deferred until a second
board with genuinely different capabilities is integrated (see Future
expansion points).

---

## Live state vs history — explicit separation

```
TelemetryProvider = live state only (latest reading + short rolling buffer)
Tier 2/3 storage  = persistence only (session history, historical analytics)
```

TelemetryProvider must never grow into a long-term data store. If a screen
needs anything older than the rolling buffer window, it reads from Tier 2/3
storage, not TelemetryProvider.

---

## Multi-device notification handling

```
- One notify subscription per connected device.
- Each notification is tagged with its originating deviceId before parsing
  (parsing happens in payload_parser.dart, per BLE payload parsing section
  above).
- This is what makes multi-device telemetry unambiguous — TelemetryProvider
  never has to guess which device a reading belongs to.
```

---

## Sensors vs Actuators — read path vs write path

Sensors (telemetry) and actuators (control) are treated as separate concepts,
each with its own path and its own data typing. They must not be merged into one
generic "peripheral" model, since a Monitor filter over actuator state (e.g.
"monitor the LED") is not a meaningful concept.

```
READ PATH (Sensors)
Board -> BleManager -> TelemetryProvider -> UI (Monitor, Device Detail, Compare,
                                                 History)

WRITE PATH (Actuators)
UI (Device Detail controls, Control screen) -> BleManagerProvider -> BleManager
                                                                    -> Board
```

- The write path does not involve TelemetryProvider at all, and does not require
  a separate "ActuatorProvider" — Control screen and Device Detail's controls
  call BleManagerProvider directly.
- Every telemetry reading is tagged with a `sensorType` field even while only one
  sensor type exists today (e.g. "voltage") — this avoids a schema migration
  later when more sensors are added. Do not build UI filtering for sensorType
  yet; that's deferred (see Future expansion points).
- Actuators should similarly carry an `actuatorType` field for the same reason,
  once more than one actuator exists.

---

## TelemetryProvider (Phase 2)

```
State shape: Map<deviceId, Map<sensorType, TelemetryReading>>
  - Outer key: deviceId
  - Inner key: sensorType (defaulted to a single type today, e.g. "voltage")
  - TelemetryReading: { deviceId, sensorType, value, timestamp }

Also maintains a rolling in-memory buffer per (deviceId, sensorType) of the last
~20-30 seconds, feeding live graphs (Tier 1 storage, below).

Exposed read methods:
  - getLatest(deviceId, sensorType)
  - getBuffer(deviceId, sensorType)
  - getAllLatest() — across all connected devices, for Monitor's default
    "All Devices" view

BleManager pushes parsed readings into TelemetryProvider (via method call or
stream subscription); TelemetryProvider has no knowledge of BLE internals.
```

Consumers of TelemetryProvider:
- **Device Detail** — filters to one deviceId, shows all its sensorTypes
- **Monitor** — reads across all deviceIds by default; later, filterable by
  deviceId and/or sensorType (UI-layer filtering only, no change to the
  provider or pipeline)
- **Compare** — reads historical data (Tier 2/3 storage, not live
  TelemetryProvider state) for multiple devices side by side
- **History** — reads Tier 2/3 storage

**Behavior on disconnect (intentionally left to the implementing ticket):**
Disconnecting a device stops future updates but does not immediately erase its
latest telemetry from TelemetryProvider. Clearing Tier 1 buffers should follow a
defined lifecycle (e.g. on disconnect, or after a reconnect timeout) determined
by the ticket that implements it — not assumed by default. Do not silently
choose one of: clearing graphs immediately, keeping stale values forever, or
wiping buffers unexpectedly. Whichever ticket first needs this behavior must
state its choice explicitly and log it in DECISIONS_LOG.md.

---

## BLE payload parsing (current, frozen protocol)

```
Characteristic notify -> raw bytes -> parse -> typed TelemetryReading

Example (ADC telemetry):
  bytes received:  0xFA 0x0B
  interpretation:  little-endian uint16
  value:           0x0BFA = 3066
  sensorType:      "voltage" (current default; extensible per-board later)

Parsing lives in a single shared utility (services/ble/payload_parser.dart) —
never inline-parsed per screen. This isolates byte-order/format knowledge in one
file so future protocol changes (JSON/CBOR, more sensors) touch one file, not
every screen or provider.
```

---

## Storage architecture (tiered)

```
Tier 1 — Real-time buffer
- In-memory only, ~20-30 seconds
- Lives inside TelemetryProvider, keyed by (deviceId, sensorType)
- Feeds: Device Detail live graph, live gauge, Monitor's live view
- Not persisted, cleared on disconnect/app restart

Tier 2 — Session history
- ~24 hours retention
- Stores: telemetry readings, connect/disconnect events, command history, RSSI
  changes, warnings
- Implementation: Hive (initial), SQLite as future upgrade path for heavier
  analytics

Tier 3 — Historical analytics
- 7 days now, 30 days future target
- Stores: historical telemetry, historical alerts, connection stability, signal
  quality trends, uptime stats
- Feeds: Monitor's Compare page, History's trends view
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

## Data flow (multi-device, current scope)

```
CC2640R2 board A          CC2640R2 board B
     │  BLE notify              │  BLE notify
     ▼                          ▼
        BleManager (real BLE, per-device streams)
                     │
                     │  parsed TelemetryReading, tagged deviceId + sensorType
                     ▼
              TelemetryProvider
     (Map<deviceId, Map<sensorType, TelemetryReading>> + rolling buffers)
                     │
       ┌─────────────┼─────────────┬─────────────┐
       ▼             ▼             ▼             ▼
  Device Detail   Monitor       Compare       History
  (one deviceId,  (all/filtered (Tier 2/3     (Tier 2/3
   all its        deviceIds,     historical,   historical)
   sensorTypes)    live)         multi-device)

Write path (separate, not shown above):
  Device Detail controls / Control screen -> BleManagerProvider -> BleManager
  -> Board (per-device, independent of TelemetryProvider)
```

---

## Explicit non-goals for this technical layer (V1)
- No replacement of Provider with Riverpod/Bloc/etc.
- No change to navigation shell (IndexedStack, bottom nav) mechanics.
- No cloud/auth dependency anywhere in this layer.
- No mesh/relay logic between boards.
- No sensorType/actuatorType filtering UI yet (data model supports it; UI is
  deferred until multiple sensor/actuator types actually exist).

---

## Future expansion points (do not implement now, but do not block later)
- Monitor gains device/sensorType filters (UI-layer only, reads same
  TelemetryProvider).
- Control gains actuatorType filters for cross-device actions, once more than
  one actuator type exists.
- Device Detail gains a per-sensor selector once a board sends more than one
  sensorType.
- Battery health indicator and digital/analog sensor count per board — likely
  additions to Device Detail (and possibly Home), tracked as evolving V1+ scope.

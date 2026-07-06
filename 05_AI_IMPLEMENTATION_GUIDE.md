# 05 — AI Implementation Guide (for Antigravity or any AI coding assistant)

This file exists because AI coding assistants have previously made unintended
architectural changes on this project. Every rule below exists to prevent that from
happening again. Read the guardrails before giving any assistant a task.

---

## Guardrails (non-negotiable)

```
- One ticket at a time. Never batch multiple tickets into one session.
- Only touch files listed under "Allowed files" for that ticket. Nothing else.
- Never refactor, rename, reformat, or "clean up" code outside the ticket's scope,
  even if it looks improvable. Flag it in a comment instead of changing it.
- Never introduce a new state-management library, new navigation pattern, or new
  folder-structure convention. Extend what exists (Provider, IndexedStack nav,
  existing services/ + state/ layout).
- Never modify firmware, BLE GATT UUIDs, or characteristic definitions. These are
  frozen. If a ticket seems to require it, stop and ask instead of guessing.
- Never modify files under services/ble/ or state/ble/ unless the ticket explicitly
  lists them as allowed — these are shared infrastructure other screens depend on.
- Before marking a ticket done: run `flutter analyze` and `flutter build` (or at
  minimum `flutter pub get` + a compile check) and confirm no new errors.
- If a requirement is ambiguous, stop and ask rather than assuming — a wrong
  assumption here compounds across every screen that depends on it.
- Commit / checkpoint before starting each ticket so it can be cleanly reverted if
  the output doesn't match acceptance criteria.
- Do not add new dependencies (pubspec.yaml packages) unless the ticket explicitly
  names one, or explicit approval is given during the plan-review step.
- Every ticket includes a Dependencies section ("Depends on: Task X.X" for
  ordering, "Requires: <interface/state shape>" for prerequisite data models) —
  do not attempt a ticket whose prerequisites aren't confirmed to exist yet.
- For non-trivial or ambiguous tickets, require an implementation plan (files to
  modify, why, assumptions) before any code is written, and wait for explicit
  approval before proceeding.
```

---

## Ticket format (used for every task below)

```
Task ID
Objective: one sentence, what this ticket delivers
Scope: what is and isn't included
Allowed files: exact files/paths that may be created or modified
Do not modify: explicitly forbidden files/areas
Dependencies: Depends on / Requires
Acceptance criteria: checklist, testable
Verification steps: how to confirm it works
```

---

## Phase 1 — Devices Screen — STATUS: COMPLETE

### Task 1.1 — Real BLE scan (replace mock scanning) — done
Real BLE scanning implemented in `ble_manager.dart` using flutter_blue_plus,
filtered by custom service UUID or device name match. Fixed during hardware
testing: name-matching now normalizes whitespace/case ("SimplePeripheral" vs
"Simple Peripheral"), and UUID matching accepts both the 128-bit and 16-bit
(`fff0`) representations. Runtime Bluetooth/location permission handling added
(kept in `BleManagerProvider`, not `BleManager`, to keep the service layer BLE-
only). Adapter-state robustness added: scan/connect are blocked while Bluetooth
is off, active scans/connections stop automatically if Bluetooth is turned off,
and the app recovers cleanly when Bluetooth/permissions are restored.

**Known bug (deferred):** when Bluetooth or location is off and Scan is pressed,
nothing happens with no visible warning to the user. The backend correctly
blocks the scan; the UI does not yet surface the ConnectionProvider error state.
Needs a small UI-layer ticket once Devices screen error/warning display is
built.

### Task 1.2 — Multi-device-ready connection state model — done
`ConnectionProvider` now tracks state via `Map<String, BleConnectionState>`
keyed by deviceId, with derived properties (`anyDeviceConnected`,
`connectedDeviceCount`, `isScanning`) instead of an ambiguous global
"current connection state." Legacy single-device behavior preserved only when
exactly one device is tracked.

### Task 1.3 — Devices Screen UI — done
Devices screen built with scan trigger, empty state, and device list. Device
Detail placeholder extracted into its own file (`screens/device_detail_page.dart`)
so Phase 2 can extend it directly. UI overflow bug (long device names +
Connect/Disconnect + menu button) fixed by moving Connect/Disconnect to its own
row below the device name.

### Task 1.4A — BLE Connection Backend — done
Real `connect(deviceId)`/`disconnect(deviceId)` implemented in `ble_manager.dart`
using flutter_blue_plus (connect, service discovery, connection state stream,
cleanup/dispose). Duplicate-connect guard in place at both UI and backend layers.

### Task 1.4B — Devices Screen Actions + Persistence — done
Connect/Disconnect wired to the real backend. Rename (alias) and Forget
implemented with local persistence via `storage/device_storage.dart`
(SharedPreferences). Forgetting a connected device disconnects it first before
clearing local state.

**Known limitation (deferred, low severity):** forgetting a device during an
active scan may occasionally allow it to reappear immediately if an
advertisement packet is already in flight in the BLE stack. Does not affect
connection stability, rename persistence, disconnect behavior, or subsequent
scans. UI consistency issue only.

---

## Phase 2 — Telemetry & Control — sensors/actuators split

Phase 2 is multi-device-first from the start, per architecture update in
03_TECHNICAL_ARCHITECTURE.md. Sensors (read path) and actuators (write path) are
separate concepts:

```
READ PATH (Sensors)
Board -> BleManager -> TelemetryProvider -> UI

WRITE PATH (Actuators)
UI -> BleManagerProvider -> BleManager -> Board
```

### Task 2.1 — Payload parsing utility (frozen protocol)
```
Objective: Create a single shared utility that parses raw BLE notify bytes into a
typed telemetry value using little-endian uint16 decoding, tagged with a sensor
type.
Scope: Pure parsing function(s) only. No UI, no providers, no BLE connection logic.
Allowed files:
  - services/ble/payload_parser.dart (new)
Do not modify:
  - Any other services/ or state/ files
Requirements:
  - Parse raw bytes (e.g. [0xFA, 0x0B]) into a uint16 value (little-endian)
  - Output a TelemetryReading object matching the canonical shape frozen in
    03_TECHNICAL_ARCHITECTURE.md: deviceId, sensorType, value, timestamp, unit
    (optional, unused today), quality/status (optional, unused today)
  - Reading model must carry a sensorType field even though only one is used today
Dependencies:
  - Depends on: none (pure utility)
  - Requires: nothing from other tasks
Acceptance criteria:
  - Correctly decodes known byte pairs (e.g. [0xFA, 0x0B] -> 3066)
  - Unit test included covering at least 2 known byte pairs
  - Reading model includes deviceId + sensorType + value + timestamp
Verification steps:
  - Run unit test, confirm passes
  - flutter analyze passes
```

### Task 2.2 — TelemetryProvider (multi-device sensor state)
```
Objective: Create a new, dedicated provider holding live telemetry readings for
all connected devices, completely separate from DeviceProvider (registry) and
ConnectionProvider (connection state).
Scope: State model only. No UI.
Allowed files:
  - state/telemetry/telemetry_provider.dart (new)
  - services/ble_manager.dart (only to wire notify-stream output into this
    provider — no changes to scanning/connection logic)
Do not modify:
  - state/device/device_provider.dart
  - state/connection/connection_provider.dart
  - screens/, widgets/
  - Firmware / BLE UUID definitions
Dependencies:
  - Depends on: Task 1.4A (real connect/notify), Task 2.1 (payload parser)
  - Requires: BleManager exposing a per-device notify stream (from 1.4A),
    payload_parser.dart's typed reading model (from 2.1)
Requirements:
  - State shape: Map<String, Map<String, TelemetryReading>> — outer key
    deviceId, inner key sensorType (structured this way from day one)
  - Rolling in-memory buffer per (deviceId, sensorType), ~20-30 seconds
    (Tier 1 storage)
  - Expose: getLatest(deviceId, sensorType), getBuffer(deviceId, sensorType),
    getAllLatest() (for Monitor's default "All Devices" view)
  - READ-PATH ONLY — must never write/command anything to a device
  - BleManager pushes parsed readings in; TelemetryProvider has no BLE-internal
    knowledge
  - One notify subscription per connected device; each notification is tagged
    with its originating deviceId before parsing (per 03_TECHNICAL_ARCHITECTURE.md)
Acceptance criteria:
  - Connecting to a real device and receiving notifications populates
    TelemetryProvider for that deviceId
  - Multiple devices tracked independently, no cross-contamination
  - Rolling buffer correctly drops readings older than ~20-30 seconds
  - DeviceProvider and ConnectionProvider remain completely unchanged
  - Explicit, stated behavior for what happens to a device's telemetry on
    disconnect (do not leave this implicit — choose and document one: clear
    immediately, clear after a timeout, or retain until reconnect/forget; log
    the choice in DECISIONS_LOG.md)
  - flutter analyze passes
Verification steps:
  - Connect one real board, confirm TelemetryProvider updates with live values
  - (If second board available) connect both, confirm independent tracking
  - Code review confirms DeviceProvider/ConnectionProvider untouched
```

### Task 2.3 — Device Detail: live status, RSSI, and rolling graph
```
Objective: Build the real (non-placeholder) Device Detail screen showing
connection status, RSSI, and a live rolling telemetry graph, sourced from
TelemetryProvider and keyed by the deviceId passed in from Devices/Home/Monitor.
Scope: Display only. Read path. No controls (that's 2.4).
Allowed files:
  - screens/device_detail_page.dart (replacing the Task 1.3 placeholder content,
    same file)
  - widgets/ (new graph/gauge widgets only, if needed)
Do not modify:
  - state/telemetry/telemetry_provider.dart
  - state/device/, state/connection/
  - Devices, Home, Monitor, Control, History screens
  - services/ble_manager.dart
Dependencies:
  - Depends on: Task 2.2
  - Requires: TelemetryProvider exposing getLatest(deviceId, sensorType) and
    getBuffer(deviceId, sensorType)
Acceptance criteria:
  - Opens from Devices/Home with the correct deviceId (same navigation as Task
    1.3 — do not change how it's opened)
  - Shows live connection status + RSSI (from ConnectionProvider, read-only)
  - Shows a live rolling graph fed by TelemetryProvider's buffer for that
    specific deviceId
  - Works correctly regardless of how many other devices are connected
  - No actuator controls present yet (explicitly out of scope for this ticket)
Verification steps:
  - Connect a real board, open its Device Detail, confirm graph updates live
  - flutter analyze passes
```

### Task 2.4 — LED control (write path)
```
Objective: Add actuator control (LED on/off) to Device Detail, using a direct
write path that does not involve TelemetryProvider at all.
Scope: Control UI + write call only. No new characteristics, no firmware
changes, no telemetry involvement.
Allowed files:
  - screens/device_detail_page.dart
  - services/ble_manager.dart (only to add/expose the write method if not
    already present)
  - state/ble/ble_manager_provider.dart (only if a thin passthrough method is
    needed to call the write)
Do not modify:
  - state/telemetry/telemetry_provider.dart
  - Any GATT UUID constants or firmware-related definitions
  - Other screens
  - state/device/, state/connection/
Dependencies:
  - Depends on: Task 2.3
  - Requires: Device Detail screen in place (from 2.3). This ticket introduces
    the write path: UI -> BleManagerProvider -> BleManager -> Board. Confirm
    this path does not route through or touch TelemetryProvider in any way.
Acceptance criteria:
  - Toggle in Device Detail sends the correct write command for that specific
    deviceId
  - Physical LED on the board responds correctly
  - Write path is fully independent of the read/telemetry path — no shared
    state or coupling
  - Works correctly per-device if multiple boards are connected (toggling
    Board A's LED must not affect Board B)
Verification steps:
  - Manual test on physical board: toggle on/off, confirm LED responds, no
    crash on rapid toggling
  - (If second board available) confirm toggling one board's LED doesn't
    affect the other
  - flutter analyze passes
```

**Note for later:** Control screen (global/cross-device actions) and Monitor's
filtering UI both reuse this same write path (2.4) and TelemetryProvider (2.2)
respectively — no new providers needed when those screens' turn comes.

---

## Deferred / future items (not scheduled, logged for later)
- UI warning when Bluetooth/location is off and Scan is pressed (Task 1.1 gap)
- Monitor/Control filtering UI (device + sensorType / actuatorType filters)
- Ability to monitor only one specific sensor of a board (Device Detail/Monitor,
  once Phase 2 telemetry display exists)
- Battery health indicator and digital/analog sensor count per board (Device
  Detail, possibly Home)
- Minor race condition: forgetting a device during an active scan may
  occasionally allow it to reappear immediately (low severity, UI consistency
  only)

---

## Phase 3+ tickets
To be written once Phase 2 is verified working. Do not pre-generate Monitor/
Control/History tickets yet — placeholder stub screens for those are covered by
04_IMPLEMENTATION_ROADMAP.md and don't need detailed tickets until their turn
comes.

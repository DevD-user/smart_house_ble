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
  names one.
```

---

## Ticket format (used for every task below)

```
Task ID
Objective: one sentence, what this ticket delivers
Scope: what is and isn't included
Allowed files: exact files/paths that may be created or modified
Do not modify: explicitly forbidden files/areas
Acceptance criteria: checklist, testable
Verification steps: how to confirm it works
```

---

## Phase 1 Tickets — Devices Screen

### Task 1.1 — Real BLE scan (replace mock scanning)
```
Objective: Replace mock device discovery with real BLE scanning for CC2640R2 boards.
Scope: Scanning only. No connect/pair/rename logic yet.
Allowed files:
  - services/ble_manager.dart
  - services/mock_ble_service.dart (only to gate/remove mock scan path)
Do not modify:
  - state/ble/ble_manager_provider.dart (unless scan result signature changes,
    in which case only the minimal adapter code)
  - Any screen file
  - Firmware / GATT UUID constants
Acceptance criteria:
  - Scanning returns real nearby BLE devices (filtered to known service UUID if
    defined)
  - Mock service is fully bypassed for scan, not deleted (kept for future testing)
Verification steps:
  - Run app on physical phone with 1 board powered on, confirm device appears in
    scan results within a few seconds
```

### Task 1.2 — Multi-device-ready connection state model
```
Objective: Extend BleManagerProvider to key connection state by deviceId instead of
a single implicit device.
Scope: State model only, not UI.
Allowed files:
  - state/ble/ble_manager_provider.dart
  - state/connection/ (relevant files)
Do not modify:
  - services/ble_manager.dart (unless a method signature must add deviceId param)
  - screens/, widgets/
Acceptance criteria:
  - Provider exposes state keyed by deviceId (e.g. Map<String, DeviceConnectionState>)
  - Existing single-device behavior still works unchanged from the UI's perspective
Verification steps:
  - Connect one device, confirm connection state updates correctly
  - Code review confirms no global/singleton "the current device" variable remains
```

Task 1.3 — Devices Screen UI
Objective: Build the Devices screen per 02_PRODUCT_ARCHITECTURE.md responsibilities.
Scope: UI + wiring to existing providers only.
Allowed files:

screens/devices_page.dart
widgets/ (new device-list-item widget only, if needed)

Do not modify:

state/ble/
services/
navigation_wrapper.dart (unless adding the route/tab entry itself)

Dependencies:

Depends on: Task 1.2
Requires: BleManagerProvider/ConnectionProvider exposing per-deviceId connection state (from Task 1.2), real scan logic in ble_manager.dart (from Task 1.1)

Acceptance criteria:

Lists scanned / known devices
Scan button starts and stops BLE scanning
Shows scanning state
Shows empty state when no devices are available
Tapping a device opens the Device Detail placeholder page
No telemetry
No controls
No connection logic
No persistence

Verification:

Manual test: scan starts, devices appear, empty state works, device tap opens placeholder

**Task 1.4A — BLE Connection Backend**

Objective: Implement real BLE connection lifecycle (connect, disconnect, service discovery) in the BLE service layer, feeding state into the existing per-deviceId connection model.

Scope: Backend/service logic only. No UI changes.

Allowed files:
- services/ble_manager.dart
- state/connection/ (only to wire real state transitions into the existing per-deviceId model — no structural rewrite of the model itself)

Do not modify:
- screens/
- widgets/
- state/device/
- navigation_wrapper.dart
- Firmware / BLE UUID definitions (read-only reference, no changes)
- state/ble/ble_manager_provider.dart (unless a method signature must expose a new connect/disconnect call — minimal addition only)

Dependencies:
- Depends on: Task 1.2
- Requires: ConnectionProvider/BleManagerProvider exposing per-deviceId connection state (from Task 1.2), scan logic returning real device IDs (from Task 1.1)

Acceptance criteria:
- `connect(deviceId)` establishes a real GATT connection to the specified device
- `disconnect(deviceId)` cleanly terminates the connection
- Service discovery runs after connect and confirms the known custom service UUID is present
- Connection state transitions correctly through connecting → connected / error, updating the Task 1.2 per-deviceId state model
- Disconnection (manual or unexpected, e.g. out of range) is detected and reflected in state
- No UI is touched; this is verified via logs/state inspection, not screen behavior

Verification steps:
- flutter analyze passes
- Manual test with real board: trigger connect, confirm GATT connection succeeds and state updates to "connected"
- Manual test: disconnect, confirm state updates to "disconnected"
- Manual test: move board out of range or power it off, confirm state reflects lost connection (not stuck on "connected")

---

**Task 1.4B — Devices Screen Actions + Persistence**

Objective: Wire the Devices screen's connect/disconnect buttons to the real backend from Task 1.4A, and add rename/forget with local persistence.

Scope: UI wiring + persistence only. No new backend connection logic.

Allowed files:
- screens/devices_page.dart
- state/device/ (only if DeviceProvider needs rename/forget methods — minimal addition, not a model rewrite)
- storage/ (new file(s) for persistence, e.g. Hive box or simple local storage for known devices)

Do not modify:
- services/ble_manager.dart
- state/connection/
- Firmware / BLE UUID definitions
- Home page
- navigation_wrapper.dart

Dependencies:
- Depends on: Task 1.4A
- Requires: real `connect(deviceId)`/`disconnect(deviceId)` methods in ble_manager.dart (from Task 1.4A)

Acceptance criteria:
- Connect/Disconnect buttons on Devices screen call the real backend and reflect live state (not placeholder logic)
- Rename updates device name in UI and persists across app restart
- Forget removes device from list and persists across app restart (device does not reappear after restart unless rediscovered via scan)
- Pair, if applicable to the BLE stack in use — otherwise mark N/A in the verification report

Verification steps:
- flutter analyze passes
- Manual test with real board: connect/disconnect via UI, confirm behavior matches 1.4A's backend state
- Manual test: rename a device, restart app, confirm name persists
- Manual test: forget a device, restart app, confirm it stays gone
--------------------------
## Phase 2 Tickets — Device Detail Screen

### Task 2.1 — Payload parsing utility (frozen protocol)
```
Objective: Create a single shared utility that parses raw BLE notify bytes into a
typed ADC value using little-endian uint16 decoding.
Scope: Pure parsing function(s), no UI, no BLE connection logic.
Allowed files:
  - services/ble/payload_parser.dart (new)
Do not modify:
  - Any other services/ or state/ files
Acceptance criteria:
  - Function takes raw bytes (e.g. [0xFA, 0x0B]) and returns correct uint16 (3066)
  - Unit test included covering at least 2 known byte pairs
Verification steps:
  - Run unit test, confirm passes
```

### Task 2.2 — Device Detail screen: connection status, RSSI, live graph
```
Objective: Build the core Device Detail view — status, RSSI, live rolling telemetry
graph fed by the real BLE notify stream.
Scope: Display only, using Task 2.1's parser and the per-device stream from
BleManagerProvider. LED control is a separate ticket (2.3).
Allowed files:
  - screens/device_detail_page.dart (new)
  - widgets/ (new graph/gauge widgets only, if needed)
Do not modify:
  - state/ble/, services/ (read-only consumption)
  - Devices, Home, Monitor, Control, History screens
Acceptance criteria:
  - Opens from Devices screen with the selected deviceId
  - Shows live connection status and RSSI
  - Shows a rolling graph of the last ~20-30 seconds of telemetry (in-memory buffer
    only, no persistence required in this ticket)
Verification steps:
  - Connect a real board, confirm graph updates live as the potentiometer is turned
```

### Task 2.3 — LED control (BLE characteristic write)
```
Objective: Add LED on/off control to Device Detail, writing to the existing frozen
BLE characteristic.
Scope: Control UI + write call only. No new characteristics, no firmware changes.
Allowed files:
  - screens/device_detail_page.dart
  - services/ble_manager.dart (only to add/expose the write method if not present)
Do not modify:
  - Any GATT UUID constants or firmware-related definitions
  - Other screens
Acceptance criteria:
  - Toggle in Device Detail sends the correct write command
  - Physical LED on the board responds correctly
Verification steps:
  - Manual test on physical board: toggle on/off, confirm LED state changes
    accordingly, confirm no crash on rapid toggling
```

---

## Phase 3+ tickets
To be written once Phases 1-2 are verified working. Do not pre-generate Monitor/
Control/History tickets yet — placeholder stub screens for those are covered by
04_IMPLEMENTATION_ROADMAP.md and don't need detailed tickets until their turn comes.

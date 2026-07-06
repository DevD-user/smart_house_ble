# 02 — Product Architecture (V1, Frozen)

This document is the single source of truth for screen responsibilities and navigation.
Any implementation task that would change what's described here must be treated as an
architecture change, not a normal ticket.

---

## Screen Map (line format)

```
Home
- Purpose: smart-home overview / "is everything okay right now"
- Contains:
  - Overall house health
  - Connected device count
  - Alert summary
  - Last synchronization time
  - Device cards (compact)
- Tap device card -> Device Detail
- Must NOT contain:
  - Large graphs
  - Voltage / sensor gauges
  - Detailed controls
  - Long logs

Devices
- Purpose: device registry & connection management
- Contains:
  - Scan for devices
  - Pair
  - Connect / Disconnect
  - Rename
  - Forget device
  - Firmware version
  - Device metadata
- Tap device -> Device Detail
- Must NOT contain:
  - Live graphs
  - Telemetry
  - Controls

Monitor
- Purpose: live multi-device monitoring
- Contains:
  - Live telemetry (multiple devices at once)
  - Multi-device graphs
  - Multi-device gauges (if useful)
  - Cross-device health status
  - Compare Mode (historical comparison across devices)
- Tap device -> Device Detail
- Must NOT contain:
  - Pairing / device management
  - Historical logs (belongs to History)

Control
- Purpose: global / cross-device smart-home actions
- Contains:
  - Emergency OFF (safety action, visually distinct from routine toggles)
  - Turn All LEDs ON/OFF
  - Future global commands
  - Future scenes / automation
- Must NOT become another Device Detail page
- All single-device detailed controls stay inside Device Detail

History
- Purpose: historical record keeping
- Contains:
  - Device logs (BLE connect/disconnect, command history)
  - Alert history
  - Session history (~24h)
  - Telemetry trends (7-30 day analytics)
  - Export (future)
- Rule of thumb vs Monitor: Monitor shows CURRENT state, History shows PAST events

Device Detail (not a bottom-nav tab)
- Purpose: single-device deep dive — the main workspace of the app
- Opened from: Home (device card), Devices (device row), Monitor (device card/line)
- NOT opened from: Control (Control is intentionally cross-device only)
- Contains:
  - Connection status
  - RSSI
  - Device information
  - Live rolling graph (~20-30s window)
  - Live gauge
  - Device controls (LED now, actuators later)
  - Device logs
  - Device health
  - Future OTA entry point
```

---

## Navigation Diagram

```
Splash
     │
     ▼
Home
 │  │  │
 │  │  └──────────────┐
 │  ▼                 │
 │ Device Detail ◄────┘
 │
 ├────────► Devices ─────► Device Detail
 │
 ├────────► Monitor ─────► Device Detail
 │
 ├────────► Control
 │
 └────────► History
```

- Bottom navigation tabs: Home, Devices, Monitor, Control, History (IndexedStack,
  already implemented — preserved as-is).
- Device Detail is a pushed page, not a tab. Same page instance/shape regardless of
  which screen it was opened from.
- Splash -> Home is the only fixed entry sequence; all other navigation is user-driven
  from the bottom nav.

---

## Data ownership rule of thumb (screen vs data lifetime)

```
Home       -> snapshot/summary data only (derived, not owned)
Devices    -> device registry data (paired list, connection state)
Monitor    -> live in-memory telemetry buffers (multi-device)
Control    -> command dispatch only, no owned data
History    -> persisted data (Hive) — sessions, alerts, trends
Device Detail -> single-device live state + single-device history slice
```

---

## Future expansion points (do not implement now, but do not block later)
- OTA update flow slots into Device Detail -> Device Settings -> Firmware Update.
- Control gains scenes/automation without changing its cross-device-only responsibility.
- History gains Export and longer retention (30 days) without new screens.
- Monitor's Compare Mode can grow into a dedicated view later if it outgrows Monitor.
- Cloud sync, push notifications, and multi-user support attach to History/Devices/
  Control later as an optional layer — never a required dependency.

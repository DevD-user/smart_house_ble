# 04 — Implementation Roadmap

Sequenced for the near-term deadline: get 1-2 microcontrollers working with basic
monitor + control functions first. Later phases are stubbed, not skipped.

```
Phase 1 — Devices screen (BLOCKING, do first)
[ ] Scan for BLE devices (real BLE, replacing mock where scanning is involved)
[ ] Connect / disconnect to a device
[ ] Pair / forget device
[ ] Rename device
[ ] Multi-device-ready state model (deviceId-keyed), even with 1 device today
[ ] Tap device -> navigates to Device Detail (placeholder ok initially)

Phase 2 — Device Detail screen (core demo functionality)
[ ] Connection status + RSSI display
[ ] Live telemetry parsing (uint16 little-endian from real BLE notify)
[ ] Live rolling graph (~20-30s buffer, in-memory)
[ ] LED control (BLE characteristic write)
[ ] Device info section (placeholder metadata acceptable)
[ ] Device logs (basic — can be minimal/stub for now)

Phase 3 — Home screen (thin wrapper)
[ ] Device cards (compact) driven off Devices/DeviceProvider state
[ ] Connected device count, last sync time
[ ] Alert summary (can be empty-state stub if alerts aren't built yet)
[ ] Tap card -> Device Detail

Phase 4 — Monitor screen (stub acceptable for deadline)
[ ] Placeholder screen ("Coming soon") acceptable short-term
[ ] Later: live multi-device graphs, Compare Mode

Phase 5 — Control screen (stub acceptable for deadline)
[ ] Placeholder screen acceptable short-term
[ ] Later: Emergency OFF, global LED toggle, future scenes

Phase 6 — History screen (stub acceptable for deadline)
[ ] Placeholder screen acceptable short-term
[ ] Later: session history, alert history, trends, export

Phase 7 — Storage layer (can trail Phase 1-2 slightly)
[ ] Hive setup for session history (24h)
[ ] Tier 1 in-memory buffer wired into Device Detail graph
[ ] Historical analytics tier (7-30 day) — after core works

Phase 8 — Alerts layer (post-core)
[ ] Generic alert model (see 03_TECHNICAL_ARCHITECTURE.md)
[ ] In-app banners/snackbars only (V1 scope)

Phase 9+ — Future (not scheduled, architecture must not block)
[ ] OTA update flow (Device Detail -> Settings)
[ ] Background notifications
[ ] Automation rule engine
[ ] Cloud sync / auth / push
```

Recommendation: Phases 1-2 are what unblock the Monday deadline. Phases 3-6 can ship
as visible-but-stubbed nav tabs so the app feels complete without spending time there
yet.

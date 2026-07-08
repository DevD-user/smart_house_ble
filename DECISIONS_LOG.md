# Decisions Log

## 1. Disconnect Policy for Live Telemetry

* **Decision Date**: 2026-07-06
* **Decision**: On device disconnection (either manual or unexpected), the `TelemetryProvider` retains the latest telemetry reading and the rolling buffer in memory. The data is cleared when:
  1. A new connection is initiated/established for that specific `deviceId`.
  2. The application is restarted.
* **Justification**:
  * Retaining the telemetry buffer immediately after disconnect allows the user to inspect the state of the device at the time of disconnection (e.g., view the graph or final readings for diagnostic purposes).
  * Clearing on a new connection attempt prevents mixing the old session's telemetry with the new session's telemetry.
* **Status**: Implemented consistently.

## 2. Session-Scoped Actuator Cache for LED Control

* **Decision Date**: 2026-07-08
* **Decision**: Implement a per-device, per-actuator, session-scoped actuator state cache in the application (`BleManager`).
  1. The cache uses a three-state model (`unknown`, `off`, `on`).
  2. The cache is initialized to `unknown` on first access.
  3. The cache is updated only after a successful BLE write.
  4. The cache is preserved across disconnect/reconnect events.
  5. The cache is cleared when the app is restarted or the device is forgotten.
* **Justification**:
  * Firmware v1's LED characteristic read callback is incomplete and cannot reliably report the true actuator state back to the application.
  * This is a deliberate application-side workaround, not a permanent replacement for hardware state synchronization.
  * The intended long-term solution is to migrate to true hardware-state synchronization in firmware v2 when it provides a correct BLE read callback implementation.
* **Status**: Implemented.

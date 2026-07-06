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

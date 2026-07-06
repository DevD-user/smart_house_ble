# 01 — Project Overview

## Vision
An IoT-enabled monitoring and control system for smart-household applications, built on
TI CC2640R2F LaunchPad boards (and custom boards later) communicating over BLE with a
Flutter mobile application. The app monitors analog/digital sensor telemetry and issues
control commands (LED now, relays/actuators later) to one or more boards simultaneously.

## Scope — Version 1 (current phase)
- Flutter application architecture redesign only. Firmware and BLE GATT profile are
  frozen and out of scope.
- Support 1–2 CC2640R2F boards connected directly to the phone via BLE (no mesh, no
  relay, no hub).
- Monitoring: raw uint16 ADC telemetry (10k potentiometer), little-endian byte parsing.
- Control: LED on/off via BLE characteristic write.
- Fully offline-first. No cloud, no auth, no internet dependency of any kind.
- Local storage only (in-memory buffer + Hive for history).
- Local in-app alerts only (banners/snackbars/cards) — no background notifications yet.

## Explicitly out of scope for V1
- OTA firmware updates (future — reserved UI slot only)
- Cloud sync / backend / push notifications
- Multi-user / household sharing
- Automation rule engine
- Mesh / relay networking between boards
- Background (minimized-app) notifications

## Objectives
1. Freeze a clean, scalable product architecture (screens + responsibilities) before
   further development — stop feature/scope drift like the previous Home-page dashboard
   sprawl.
2. Preserve the existing Flutter foundation (Provider architecture, navigation shell,
   theme system, BLE abstraction layer) — this is a refactor to match a frozen
   architecture, not a rewrite.
3. Design the app so it assumes multiple simultaneous BLE peripherals from day one, even
   though only 1–2 boards exist right now.
4. Produce documentation that doubles as an implementation spec for AI coding assistants
   (Antigravity), broken into small, isolated, verifiable tasks.

## Guiding constraints (apply to every phase, present and future)
- Offline-first: BLE + local storage must work with zero internet connection, always.
- Firmware and current GATT profile are stable and must not be redesigned.
- Cloud, OTA, automation, and mesh are additive future layers — never blockers for V1.
- Existing Provider/navigation/theme foundations are preserved and extended, not
  replaced.

## Current priority order
1. Stable embedded firmware (already done, frozen)
2. Stable Flutter BLE architecture (real BLE replacing mock, multi-device ready)
3. Multi-device local monitoring
4. Local history and analytics
5. Cloud functionality (not before the above is mature)

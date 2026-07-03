# UI/UX Master Plan & Frontend Design Blueprint
## Project: IoT-Enabled Smart Household Monitoring and Control System

This document establishes the permanent frontend user interface (UI) and user experience (UX) specifications for the Smart House BLE mobile client. It outlines styling tokens, page layouts, navigation rules, telemetry stream rendering pipelines, and architectural rules to deliver a premium, commercial-grade product.

---

### 1. Frontend Design Philosophy
The application interface must avoid looking like an amateur developer utility, simple serial console, or basic BLE scanner. It is designed to look and feel like a premium, consumer-facing **smart home operating system** (comparable to Samsung SmartThings).

The application uses:
*   **Minimal clean card system**
*   **Subtle Samsung SmartThings inspired design accents**
*   **Soft premium depth effects**
*   **Solid card containers**
*   **Minimal shadows**
*   **Professional flat elevation design**

#### Core Design Mandates:
*   **Aesthetic Quality:** High-fidelity layouts with clean spacing, cohesive color palettes, and solid card containers with minimal shadows.
*   **Systemic Unity:** Unified component styles across all boards, pages, and interaction panels.
*   **Intuitive Presentation:** Complex data (such as voltage levels and raw ADC readings) presented through user-friendly gauges, sparklines, and status badges.
*   **Responsive Control:** Low-latency command execution coupled with micro-animations and immediate tactile feedback.

---

### 2. Core Design Principles
To maintain a high-quality user experience, the UI system enforces the following principles:
*   **Smooth Motion:** Transitions, page swaps, state toggles, and gauges should animate smoothly (targeting $\ge 60$ FPS).
*   **Minimalist Clarity:** Keep the screen free of unnecessary developer labels. Use card containers to group and isolate related parameters.
*   **Samsung SmartThings Inspired Style:** Flat, pill-shaped accents, container layouts, distinct status badges, and rounded tiles.
*   **Geometry Consistency:** Enforce standard corner radiuses for cards ($16\text{dp}$ to $24\text{dp}$) and buttons ($12\text{dp}$ to $16\text{dp}$).
*   **Low Interactivity Latency:** The system must respond to user actions immediately, providing a visual confirmation and rolling back states if hardware writes fail.

---

### 3. Application Navigation Architecture
The app uses a globally persistent **Bottom Navigation Bar** for primary navigation. 

```
+-----------------------------------------------------------------+
|                                                                 |
|                          ACTIVE SCREEN                          |
|                                                                 |
+-----------------------------------------------------------------+
|     [Home]     [Devices]     [Monitor]     [Control]   [History]|
+-----------------------------------------------------------------+
```

#### Navigation Rules:
1.  **Persistent Layout:** The bottom navigation bar must remain visible across the app, ensuring users can switch tabs at any time.
2.  **No Tab Confusions:** Do not combine top tabs and bottom bars on the same page.
3.  **Performant Page Swaps:** Use `IndexedStack` or pre-cached PageView controllers to keep page states active, avoiding reloading telemetry streams when switching tabs.
4.  **Product-Friendly Terminology:** Avoid technical developer jargon. Use clear, consumer-friendly labels:
    *   **Home:** Primary dashboard and metrics overview.
    *   **Devices:** Connected node lists and status profiles.
    *   **Monitor:** Deep telemetry logging and graph views.
    *   **Control:** Manual command triggers and logs.
    *   **History:** Event log timeline.

---

### 4. Splash Screen Architecture
To build a premium product feel, the application boots using a custom splash screen.
*   **Display Duration:** Maximum $1.5\text{ seconds}$ (or until initial BLE radio initialization is complete).
*   **Content:** Centered "Smart House BLE" title with a custom pulsing network ring logo.
*   **Transition:** Upon initialization, the splash screen fades out smoothly as the Home Screen fades in ($300\text{ms}$ duration).

---

### 5. Home Screen (Primary Dashboard)
The primary landing dashboard displays active node telemetry and system status at a glance. It features a centerpiece design inspired by the premium Tesla dashboard telemetry layout, positioning the circular gauge as the central focus.

#### Approved Home Screen Layout:
1.  **BLE Connection Card (Top):**
    *   *Information:* Shows the connected node name (e.g., "CC2640R2 LaunchPad"), RSSI signal strength (e.g., `-61 dBm`), connection duration, and a glowing connection health indicator.
2.  **Circular Telemetry Gauge (Middle Centerpiece):**
    *   *Information:* A large premium circular gauge positioned centrally on the screen. The telemetry gauge represents live hardware readings and visually reacts as values approach the currently calibrated hardware maximum (such as the firmware-discovered ~3066 ADC count ceiling).
    *   *Value Display:* The current live voltage value (e.g., **2.47 V**) and raw ADC value are rendered **inside the center** of the circular gauge.
3.  **Mini Live Graph (Below Gauge):**
    *   *Information:* A line chart showing a rolling 20-second history window of voltage readings, updating dynamically.
4.  **Quick Controls (Bottom):**
    *   *Information:* Contains interactive toggles for board peripherals:
        *   Red LED Toggle
        *   Green LED Toggle
        *   Emergency OFF button (resets all states immediately)

---

### 6. Devices Page
Manages the household node directory.
*   **Current Phase:** Supports a single point-to-point connection to the CC2640R2 LaunchPad.
*   **Future Scope:** Displays a grid of discovered accessories (e.g., "Kitchen Node", "Bedroom Node", "Garage Node").
*   **Card Layout:** Clean, minimal tiles displaying device name, active status, RSSI, and last-seen timestamp.
*   **Current Device Card Fields:**
    *   Device alias/name
    *   Connection status
    *   RSSI signal strength
    *   Last active timestamp
*   **Battery Status Note:** Battery monitoring does **NOT** currently exist. Battery telemetry is reserved for future hardware revisions. Future hardware versions may include battery monitoring support, but the current application version does **NOT** display battery status.

---

### 7. Device Detail View
When a device card is selected, the application transitions to a dedicated board detail page.
*   **Transition:** Shared axis transition animation ($300\text{ms}$).
*   **Content:** Aggregated device specs, detailed telemetry curves, historical logs, device-specific configurations, and future reserved configuration controls.
*   **Future Reserved Configuration Controls:**
    *   *Description:* The Device Detail View may include future reserved configuration controls intended for future hardware versions and future firmware capabilities.
    *   *Constraint:* The current application version does **NOT** support calibration interfaces. Do **NOT** implement calibration UI (such as calibration sliders or ADC calibration controls) in the current architecture.

---

### 8. Monitor Page
Designed for reviewing telemetry curves.
*   **Macro Graph:** A smoothed spline chart with interactive time-range filters (1 Min, 5 Min, 15 Min, 1 Hour).
*   **Statistical Cards:** Quick-view metric cards displaying Max, Min, Current, and Moving Average values.
*   **Automated Sensor Analysis:** An intelligent message box outputting status updates:
    *   `Stable Signal Detected` (normal variance)
    *   `Rapid Fluctuation Detected` (noise anomaly)
    *   `Voltage Spike Detected` (abrupt transition)
    *   `Connection Instability Detected` (dropped packets)

---

### 9. Control Page
Provides direct control over connected peripheral hardware.
*   **LED Controller Cards:** Individual status panels containing on/off switches and status icons (Red/Green LED).
*   **BLE Command Monitor:** A terminal card displaying commands written to Characteristic `0xD822` in real time:
    *   `15:22:10 -> Sent [01 01] -> Red LED ON`
    *   `15:22:15 -> Sent [01 00] -> Red LED OFF`
*   **Future Expansion Space:** Placeholders to support relays, smart plugs, active fans, and analog dimmers.

---

### 10. History Page
A chronological database of system actions and events.
*   **Timeline View:** Displays connection changes, notification states, automation triggers, voltage alerts, and user command inputs.
*   **Filter Chips:** Allows filtering log data by Category:
    *   `[All Logs]` `[BLE Events]` `[Sensor History]` `[Command Events]`

---

### 11. Device Comparison System
An analytics dashboard for multi-node deployments.
*   **Comparison Interface:** Multi-line charts mapping voltage trends, signal values, and node uptimes simultaneously.
*   **Color Mapping:** Automatically assigns distinct colors to different nodes (e.g., Blue for Kitchen Node, Green for Bedroom Node).

---

### 12. Theme System
The visual style adapts to Light and Dark modes.
*   **Interactivity Rule:** The theme toggle is located **only on the Home Screen** to maintain layout consistency.
*   **Icons:** Shows a Moon icon during dark mode, and a Sun icon during light mode.

---

### 13. Theme Transition Animation
To keep the UX clean, theme changes use a visual transition:
*   **Specification:** A fade transition coupled with a rotation vector on the icon. The Sun smoothly transforms into the Moon, and vice-versa, over a $300\text{ms}$ interval.

---

### 14. UX Performance Rules
To prevent telemetry updates from dropping frames below $60\text{ FPS}$:
1.  **Isolate Rebuilds:** Minimize the use of global state updates (`notifyListeners()`). Telemetry values should update local components without rebuilding parent page layouts.
2.  **Telemetry-Specific Consumers:** Wrap high-frequency telemetry widgets (like graphs and gauges) in dedicated Consumers, or update values using `StreamBuilder`/`ValueNotifier`.
3.  **Lightweight Charts:** Ensure graph rendering is lightweight by limiting repaints and using pre-computed path lines.

---

### 14-B. Telemetry Stream Optimizations & State Scoping

High-frequency telemetry updates can increase rendering load. The following optimization rules are enforced:

```
                    +------------------------------------+
                    |        Incoming BLE Stream         |
                    |       (100ms Update Packet)        |
                    +-----------------+------------------+
                                      |
                                      v
                    +-----------------+------------------+
                    |    Hardware Dead-Band Filter       |
                    |      (Threshold Check: +/-4)       |
                    +-----------------+------------------+
                                      | (Change > Threshold)
                                      v
                    +-----------------+------------------+
                    |    Background Telemetry Service    |
                    |     (Persistent Connection State)  |
                    +--------+------------------+--------+
                             |                  |
        (Repaint: 100ms)     v                  v     (Repaint: 250ms)
                    +--------+---------+      +-+----------------+
                    |  Circular Gauge  |      | Rolling Graph    |
                    |  Voltage Card    |      | (20s Max Buffer) |
                    +------------------+      +------------------+
```

1.  **Reactive Data Isolation:** Do not call broad notify loops on parent widgets. Update gauges and text cards using localized `ValueListenableBuilder` or `StreamBuilder` widgets to protect performance.
2.  **Persistent Background Telemetry:** BLE subscriptions must run inside persistent background services independent of the UI lifecycle. Swapping tabs on the navigation bar must not interrupt telemetry collection or disconnect the BLE link.
3.  **Hardware Dead-Band Filter:** Implement software hysteresis. If an incoming raw ADC reading changes by less than $\pm 4$ counts compared to the last processed value, skip UI updates and graph repaints.
4.  **Graph Memory Optimization:** Rolling charts must cap data arrays at 20 seconds. Discard older telemetry data points automatically to prevent unbounded memory growth.
5.  **Frame Rate Protection:** Telemetry processing must not block the main UI thread. Avoid heavy layouts and layouts with variable heights during telemetry updates.

---

### 14-C. Battery and Resource Optimization
*   **App Lifecycle Handlers:** When the application moves to the background state, suspend only heavy UI rendering operations (such as graph rendering, gauge animations, and heavy UI repainting). Do **NOT** suspend the BLE connection, BLE notification streams, or background telemetry processing. The BLE communication layer must remain active independently of the UI lifecycle to support future multi-board monitoring, alert systems, and continuous background data collection.
*   **Page Inactivity Adjustments:** Reduce telemetry UI refresh rates when the home page is not active in the viewport, while preserving active background BLE processing.

---

### 14-D. Telemetry Rendering Pipeline
Separates raw telemetry collection speed from UI rendering rates to improve CPU efficiency:

```
+-----------------------------------+
| CC2640R2 MCU Firmware Notification| -> Every 100ms (Raw Telemetry)
+-----------------+-----------------+
                  v
+-----------------------------------+
|  Flutter BLE Ingest (Stream Link) | -> Reads and parses bytes every 100ms
+-----------------+-----------------+
                  v
+-----------------------------------+
| Live Voltage Card & Circular Gauge| -> Renders updates every 100ms
+-----------------+-----------------+
                  v
+-----------------------------------+
|    Graph Telemetry Refresh        | -> Repaints chart every 250ms
+-----------------+-----------------+
                  v
+-----------------------------------+
|   History & Database Write        | -> Saves log entries every 500ms
+-----------------------------------+
```

---

### 15. Orientation Behavior
*   **Setting:** Forced portrait mode only (`DeviceOrientation.portraitUp`). 
*   **Reason:** Keeps layout structures stable, prevents graph distortion, and ensures consistent dashboard scaling.

---

### 16. UX Interaction Philosophy
To make the application feel responsive and alive:
*   **Press Feedback:** Implement subtle card scaling animations (`ScaleTransition` or custom touch listeners) during user interaction.
*   **Animated Status Switches:** LED and relay controls should animate status transitions.
*   **Command Feedback:** Provide immediate feedback (e.g. status changes and loading indicators) when writing commands, and show error overlays (such as SnackBar alerts) with state rollbacks if BLE transmissions fail.

---

### 17. Design Language Specifications

#### Theme Palettes:
*   **Dark Mode (Default):**
    *   *Background:* `#0F1115`
    *   *Cards/Panels:* `#1A1D24`
    *   *Accent Colors:* `#00E5FF` (Cyan), `#2979FF` (Electric Blue)
*   **Light Mode:**
    *   *Background:* `#F7F9FC`
    *   *Cards/Panels:* `#FFFFFF`
    *   *Accent Colors:* `#1A237E` (Deep Navy), `#00B0FF` (Light Cyan)

#### Typography:
*   *Font Family:* System default sans-serif (e.g., Roboto / San Francisco / Inter).
*   *Headers:* Large, clean font faces with comfortable line heights.

#### Cards Layout:
*   *Style:* Minimalist, clean cards with soft dropshadows.
*   *Corner Radius:* $16\text{dp}$ to $24\text{dp}$.

---

### 18. Settings Page Architecture Decision
*   **Current Version:** A settings page is **postponed** as the initial version focuses on core dashboard controls and telemetry graph rendering.
*   **Future Scope:** A settings tab will be added to configure BLE scan timeout rates, developer logs, future device configuration parameters, alarm thresholds, and OTA firmware updates.

---

### 19. Offline Architecture
*   **Requirement:** The application must remain functional when disconnected from the hardware node.
*   **Implementation:** If no physical BLE hardware is detected, the app uses `MockBleService` to simulate telemetry streams, enabling UI and graph validation.

---

### 20. Error State Handling
*   **Disconnection Warnings:** Show an overlay card if the BLE link drops unexpectedly.
*   **Stale Data Warnings:** Fade telemetry displays and show a warning badge if sensor notifications time out (e.g., if no updates are received for over 2 seconds).
*   **Transmission Errors:** Display a SnackBar alert with a manual retry option if command writes fail.

---

### 21. Local Storage System
*   **Target Data:** Persists theme preferences, device aliases, and recent log data.
*   **Technology Candidate:** `Hive` or `SharedPreferences` for configuration data, and `SQLite` for telemetry databases.

---

### 22. Protected Architecture Rules

> [!IMPORTANT]
> The following system layers are protected. AI coding agents must **NOT** modify these directories or attributes without explicit approval.

*   **Protected Core Files:**
    *   Embedded firmware configuration files in `C:\TI_WORKSPACE\simple_peripheral`.
    *   BLE custom profile structures and UUID definitions (`0xD820` Service UUID, `0xD821`/`0xD822` Characteristic UUIDs).
    *   Flutter state Provider architecture maps.
    *   Service abstraction files ([ble_manager.dart](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/services/ble_manager.dart)).
*   **Allowed Modification Zones:**
    *   UI components, widgets, cards, and page layout architectures.
    *   Theme properties, gradients, palette definitions, and icon morph animations.
    *   Sparkline graphs, telemetry gauges, and monitoring cards.
    *   Navigation pathways and Bottom Navigation styles.

---

### 23. Future Expansion Architecture
*   **Multi-Node Processing:** Update providers to support lists of `SmartDevice` models instead of single nodes.
*   **Sensor Expansion:** Add display configurations for temperature, humidity, and touch sensors.
*   **Automation Configuration:** Implement rule editors to trigger relay toggles based on sensor thresholds.

---

### 24. Current Development Priority
1.  **Dashboard Redesign:** Polish UI widgets to align with the design specifications (custom gauges, rolling charts, solid container cards).
2.  **BLE Integration:** Replace the simulated data provider with real BLE interfaces, keeping firmware settings frozen.

---

### 25. Approved Flutter Package Policy
External Flutter package selection must prioritize long-term maintainability, performance efficiency, and low widget rebuild overhead.

#### Approved Packages:
*   **BLE Communication:**
    *   `flutter_blue_plus` (Preferred BLE package)
*   **Graph Rendering:**
    *   `fl_chart` (Preferred graph package)
*   **State Management:**
    *   `provider` (Already active architecture)
*   **Local Storage:**
    *   `Hive`
    *   `SQLite`
    *   `SharedPreferences`
*   **Animation System:**
    *   *Preferred:* Built-in Flutter animation framework (e.g., `AnimatedContainer`, `AnimatedSwitcher`, `AnimationController`, `TweenAnimationBuilder`).

#### Rules:
*   Avoid unnecessary third-party packages and package bloat.
*   Do not install packages that rebuild entire widget trees unnecessarily.
*   Avoid packages with poor maintenance status or excessively large dependency trees.
*   *Development Priority:* Performance is more important than visual complexity.
*   *Rule:* Do not add new dependencies without architectural review.

---

### 26. AI Development Safety Rules

This project is developed collaboratively using multiple AI coding systems.

Current AI systems involved in development:
*   Antigravity
*   Gemini
*   Claude
*   ChatGPT
*   Future AI coding assistants

Future AI systems working on this project must obey strict development boundaries.

#### Core Rules:
1. Never regenerate the entire project architecture unless explicitly requested.
2. Do not modify existing Flutter Provider architecture.
3. Do not replace `flutter_blue_plus` package without explicit approval.
4. Do not modify BLE UUID definitions.
   *   *Protected UUIDs:*
       *   Service UUID $\rightarrow$ `0xD820`
       *   ADC Characteristic $\rightarrow$ `0xD821`
       *   LED Control Characteristic $\rightarrow$ `0xD822`
5. Do not modify embedded firmware architecture located in: `C:\TI_WORKSPACE\simple_peripheral`.
6. Do not install unnecessary Flutter packages.
7. UI redesign tasks must preserve backend logic.
8. New widgets must avoid unnecessary widget rebuilds.
9. Do not introduce architecture-breaking refactors.
10. Do not modify BLE packet structure.
    *   *Current packet architecture:* `[Peripheral_ID, Value]`
    *   *Examples:*
        *   `[1,1]` $\rightarrow$ Red LED ON
        *   `[1,0]` $\rightarrow$ Red LED OFF
        *   `[2,1]` $\rightarrow$ Green LED ON
        *   `[2,0]` $\rightarrow$ Green LED OFF
11. If uncertain, modify UI layers only.

#### Allowed Modification Zones:
*   UI widgets
*   Theme system
*   Animations
*   Typography
*   Navigation
*   Card styling
*   Graph rendering
*   Page layouts

#### Protected Zones:
*   Firmware architecture
*   BLE packet structure
*   Provider architecture
*   Service abstraction layer
*   UUID definitions

> [!IMPORTANT]
> **Priority Rule:** Preserve project architecture stability above all else. Future AI systems must prioritize architectural continuity over code generation convenience.

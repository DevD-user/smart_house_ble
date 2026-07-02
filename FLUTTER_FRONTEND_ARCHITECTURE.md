# IoT-Enabled Smart Household Monitoring and Control System
## Flutter Frontend Architecture Documentation

---

### Table of Contents
1. [Flutter Application Overview](#1-flutter-application-overview)
2. [Project Structure](#2-project-structure)
3. [State Management Architecture](#3-state-management-architecture)
4. [BLE Service Layer](#4-ble-service-layer)
5. [Screen Architecture](#5-screen-architecture)
6. [Theme System](#6-theme-system)
7. [Planned UI Architecture](#7-planned-ui-architecture)
8. [BLE Integration Pipeline](#8-ble-integration-pipeline)
9. [Testing Strategy](#9-testing-strategy)
10. [Future App Expansion](#10-future-app-expansion)

---

### 1. Flutter Application Overview
The Flutter application acts as the client control terminal (BLE Central) in the smart household system. Written in Dart, the app connects to one or more peripheral devices (BLE Peripherals) to display live telemetry feeds and command actuators. 

The application utilizes high-performance, asynchronous stream listeners to capture real-time voltage data from analog-to-digital converters (ADC) and pushes write command arrays to command external peripherals (e.g., LED lights, active relays). The architecture is designed to run efficiently on both Android and iOS devices, implementing separation of concerns, reactive state management, and reusable interface modules.

---

### 2. Project Structure
The frontend codebase layout separates domain logic, UI presentations, services, and state containers:

```
lib/
├── capabilities/         # Core hardware capability behaviors
├── main.dart             # Application bootstrapper and multi-provider config
├── models/               # Domain data models (devices, capabilities, enums)
│   ├── capability_types.dart
│   ├── device_capability.dart
│   └── smart_device.dart
├── screens/              # Top-level application view controllers
│   └── dashboard_screen.dart
├── services/             # API clients, communications, and simulator services
│   ├── ble_manager.dart
│   └── mock_ble_service.dart
├── state/                # Provider layers managing state flows
│   ├── ble/
│   │   └── ble_manager_provider.dart
│   ├── connection/
│   │   └── connection_provider.dart
│   ├── device/
│   │   └── device_provider.dart
│   └── theme/
│       └── theme_provider.dart
├── theme/                # UI styling assets, tokens, and Material themes
│   └── app_theme.dart
└── widgets/              # Reusable components and presentation cards
    └── device_card.dart
```

---

### 3. State Management Architecture
State management is implemented using the **Provider** framework. Providers decouple underlying business logic from widget rendering, preventing redundant component redraws and establishing single sources of truth.

```
                  +--------------------------------+
                  |           MultiProvider        |
                  +---------------+----------------+
                                  |
         +------------------------+------------------------+
         |                        |                        |
         v                        v                        v
+------------------+     +------------------+     +------------------+
|  DeviceProvider  |     |ConnectionProvider|     |  ThemeProvider   |
+--------+---------+     +--------+---------+     +------------------+
         |                        |
         +-----------+------------+
                     |
                     v (Proxy Injection)
        +----------------------------+
        |     BleManagerProvider     |
        +----------------------------+
```

*   **BleManagerProvider:** Acts as a wrapper around the low-level `BleManager` controller. It uses a `ChangeNotifierProxyProvider2` pattern injected during bootstrapping to dynamically acquire active references of `DeviceProvider` and `ConnectionProvider`. Exposes simulation controls (`startSimulation()`, `stopSimulation()`) directly to developer-facing widgets.
*   **ConnectionProvider:** Tracks the current system connectivity status. Exposes:
    *   `connectionState`: An instance of `BleConnectionState` (`idle`, `scanning`, `connecting`, `connected`, `reconnecting`, `error`).
    *   `isBluetoothEnabled`: Tracks the hardware radio state.
    *   `connectedDeviceCount`: Number of active nodes with established connections.
    *   `lastError`: Tracks connection timeouts or configuration failures.
*   **DeviceProvider:** Holds an in-memory database of active smart peripherals represented as a key-value map.
    *   Maintains the `_devices` map (accessible as a read-only unmodifiable map).
    *   Provides operations to register new devices (`addDevice`), detach nodes (`removeDevice`), and update specific values on an existing node (`updateDeviceCapability`).
*   **ThemeProvider:** Exposes light/dark mode settings and handles immediate UI updates. Interconnects with user preference configurations for custom visual schemes.

---

### 4. BLE Service Layer
The BLE Service Layer encapsulates Bluetooth communication and data formatting logic.

*   **`ble_manager.dart` (BleManager):**
    *   Manages connection events and subscribes to telemetry streams.
    *   Performs structural serialization and deserialization of BLE characteristics.
    *   Converts physical stream maps into clean calls to `DeviceProvider` for data persistence.
    *   Contains the business logic to toggle physical device outputs (writes to Characteristic `0xD822`).
*   **`mock_ble_service.dart` (MockBleService):**
    *   A local developer testing module that simulates real hardware when physically disconnected from the MCU LaunchPad.
    *   Uses a periodic timer (default: every 2 seconds) to stream generated double voltages (1.0V to 3.3V) and random battery drops (50% to 100%) mimicking real sensor data streams.
    *   Exposes a broadcast `Stream<Map<String, dynamic>>` consumed by `BleManager`.

---

### 5. Screen Architecture
Views are designed to be thin, offloading layout configuration to responsive widgets and business logic to Providers.

*   **`dashboard_screen.dart` (DashboardScreen):**
    *   The primary interface layout.
    *   Presents a status header indicating connection counts and scanning states.
    *   Provides quick toggles to engage real hardware BLE scanning or trigger local mock telemetry simulations.
    *   Renders a dynamically updating list of `DeviceCard` widgets.
*   **Planned `control_screen.dart` (ControlScreen):**
    *   A dedicated detail panel displaying telemetry analysis graphs and multi-peripheral control options.
    *   Houses advanced switches for actuators, RGB color pickers, and threshold alerts configuration.

---

### 6. Theme System
The UI adopts a unified layout utilizing Material 3 specs:
*   **Dark Mode:** Default visual theme. Built on black and dark grey background planes, using electric blue (`#0D9488` / `#00D2C4`) and neon accent colors to minimize eye strain and reduce power usage on OLED displays.
*   **Light Mode:** Clean, high-contrast visual option. Employs light grey backgrounds with deep navy typography for readable outdoor monitoring.
*   **Persistent Switching:** Handled automatically by rebuilding the parent `MaterialApp` upon changes in `ThemeProvider.isDarkMode`. Future versions will record user selections persistently to disk using local storage options (such as `shared_preferences`).

---

### 7. Planned UI Architecture
The next stage of development introduces a **Samsung SmartThings inspired UI design** focused on clarity and ease of use:

```
+-------------------------------------------------------------+
|                      DASHBOARD SCREEN                       |
|  [Header Card: BLE Central Status (Scan / Connect Stats)]   |
|                                                             |
|  +-------------------------------------------------------+  |
|  |                     DEVICE CARD                       |  |
|  |  Node A: Active                                       |  |
|  |  +-------------------------------------------------+  |  |
|  |  |           Live Voltage Display Gauge            |  |  |
|  |  |              [== 2.45 V ==]                     |  |  |
|  |  +-------------------------------------------------+  |  |
|  |  +-------------------------------------------------+  |  |
|  |  |           Live Graph (Sparkline Trend)          |  |  |
|  |  |           /\_/\_/\__                            |  |  |
|  |  +-------------------------------------------------+  |  |
|  |  +-------------------------------------------------+  |  |
|  |  |           Peripheral Control Buttons            |  |  |
|  |  |           [LED Toggle]      [Relay Off]         |  |  |
|  |  +-------------------------------------------------+  |  |
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
```

*   **Dashboard Page:** Clean Grid layout aggregating telemetry metrics, connectivity signals, and immediate control switches.
*   **Controls Page:** Slide-up detailed menu allowing manual parameters configuration, ADC polling speed adjustments, and automation triggers setup.
*   **Voltage Display Card:** Features a circular gauge presenting real-time voltage levels (0V–3.3V) with dynamic color gradients corresponding to voltage thresholds.
*   **Live Graph:** A scrolling line chart rendering incoming ADC telemetry updates to highlight sensor noise and voltage trends over time.
*   **Connection Card:** Aggregated device network monitor card detailing signal quality (RSSI indicator) and node health status.
*   **BLE Device Monitoring:** System logs showing active device handshakes, transmission packets counts, and battery status.
*   **LED Control Toggles:** Clean tactile buttons executing quick writes to Characteristic `0xD822` to switch LEDs.
*   **Portrait Mode Lock:** The app forces vertical alignment using `SystemChrome` constraints to maintain dashboard layout integrity.

---

### 8. BLE Integration Pipeline

The diagram below details the data parsing and rendering flow:

```
+--------------------------+
|  TI CC2640R2 LaunchPad   |
|  Reads ADC (DIO23)       |
+------------+-------------+
             |
             v (GATT Notification)
+------------+-------------+
|    BleManager (Dart)     |
|  Listens to stream data  |
|  and decodes bytes       |
+------------+-------------+
             |
             v (Map to Model Update)
+------------+-------------+
|   DeviceProvider (State) |
|  Triggers notifyListeners|
+------------+-------------+
             |
             v (Rebuild Notification)
+------------+-------------+
|  Dashboard UI (Consumer) |
|  Redraws gauges / graphs |
+--------------------------+
```

1.  **Notification Ingest:** Physical MCU notifies a byte change on Characteristic `0xD821`.
2.  **Manager Parsing:** `BleManager` stream listener captures the raw 2-byte package and parses the data (representing the little-endian formatted uint16).
3.  **State Insertion:** Manager invokes `DeviceProvider.updateDeviceCapability(deviceId, 1, parsedVoltage)` with the updated value.
4.  **Widget Redraw:** Providers dispatch changes through `notifyListeners()`, causing `Consumer` widgets to redraw elements (such as gauges and charts) with low-overhead rendering routines.

---

### 9. Testing Strategy

*   **Mock BLE Simulation:** Telemetry is validated on the simulator via `MockBleService`. This simulates packet variance and disconnection edge cases, ensuring UI components adjust without needing physical target hardware attached.
*   **Real Hardware Integration:** Validated by scanning, connecting, and verifying service discovery using real TI LaunchPad hardware. Debug logs monitor characteristics connection states and output structures.
*   **Notification Testing:** Telemetry changes are verified under load. We test incoming notification events up to 10Hz to verify that the Flutter UI updates smoothly and that Providers do not cause memory leaks during prolonged runtimes.

---

### 10. Future App Expansion

*   **Multiple Board Monitoring:** Update `BleManager` to handle concurrent connections to multiple MCU nodes, displaying distinct, card-based telemetry metrics side-by-side.
*   **Device Grouping:** Add features to group device nodes into rooms or virtual zones, enabling global commands (e.g., "Turn off all living room LEDs").
*   **Smart Home Dashboard:** Expand the layout to show full household automation status, grouping security alerts, environmental temperature feeds, and energy monitors.
*   **Sensor Analytics:** Integrate a local database engine (such as Hive or SQLite) to store telemetry history. This will enable analytics, such as average power usage, trend reports, and historical anomaly detection.

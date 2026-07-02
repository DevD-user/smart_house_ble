# Technical Project Context Transfer
## Project: IoT-Enabled Smart Household Monitoring and Control System

This document provides a concise, information-dense reference to transfer complete technical context of the smart household system to another developer, AI system, or future engineering session.

---

### 1. Project Summary
An embedded IoT smart household monitoring and control platform linking a local sensor-actuator node (BLE Peripheral) with a mobile controller application (BLE Central).
*   **Primary Telemetry:** Potentiometer analog voltage reads, digitized via MCU ADC, streamed over BLE notifications.
*   **Primary Actuation:** Remote commands written over BLE to toggle physical indicators (LEDs) on the board.
*   **Key Design Goal:** Fast, low-latency, low-power bi-directional communications to serve as a foundation for scalable home automation.

---

### 2. Hardware Stack
*   **TI CC2640R2 LaunchPad:** Central MCU evaluation board hosting the RF Core (BLE stack) and application tasks under TI-RTOS.
*   **Custom CC2640R2F Board (Planned):** Target hardware for production layout and optimized power footprint.
*   **10k Potentiometer:** Analog input source wired to:
    *   *VCC:* 3.3V (J1.1)
    *   *GND:* GND (J1.2)
    *   *Signal Wiper:* `DIO23` (J1.4, bound to logical driver `Board_ADC0`).
*   **Breadboard & Jumper Wires:** Connective bus for prototyping.
*   **Android Smartphone:** BLE Central central client device running the Flutter application.

---

### 3. Firmware Architecture
*   **Codebase Base:** TI BLE5 Stack `simple_peripheral` project compiled inside Code Composer Studio (CCS).
*   **Task Execution Model:** TI-RTOS kernel using task thread contexts, software timers (`Clock_Struct`), and event message queues.
*   **Completed Implementations:**
    *   BLE custom service registration and advertising loop.
    *   Periodic 100ms ADC conversion events (`SP_PERIODIC_ADC_EVT`).
    *   GATT write callbacks triggering thread-safe GPIO changes (`SP_POTLED_CHAR_CHANGE_EVT`).
    *   Asynchronous BLE notification propagation using CCCD subscriptions.
*   **Firmware Project Location:** `C:\TI_WORKSPACE\simple_peripheral`

---

### 4. Custom BLE Service Design
*   **Custom GATT Profile:** PotLed Service
*   **Service UUID:** `48c5d820-ac2a-11e7-abc4-cec278b6b50a` (Short ID: `0xD820`)

| Characteristic Name | UUID | Permissions | Data Type / Struct | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **`POTLED_ADC_VALUE`** | `0xD821` | Read & Notify | `uint16_t` (2 bytes) | Transmits raw 12-bit ADC values (0–4095) |
| **`POTLED_LED_STATE`** | `0xD822` | Read & Write | `uint8_t[2]` (2 bytes) | Command format: `[Peripheral_ID, Value]` |

#### Command Map (`0xD822`):
*   `[1, 1]` $\rightarrow$ Red LED ON
*   `[1, 0]` $\rightarrow$ Red LED OFF
*   `[2, 1]` $\rightarrow$ Green LED ON
*   `[2, 0]` $\rightarrow$ Green LED OFF

---

### 5. ADC System
*   **Channel Mapping:** `DIO23` mapped as `Board_ADC0` inside target board mapping overrides (`CC2640R2_LAUNCHXL.c` / `.h`).
*   **Execution Pipeline:**
    $$\text{Potentiometer Voltage} \rightarrow \text{ADC\_convert()} \rightarrow \text{PotLedService\_SetParameter()} \rightarrow \text{GATT Notification} \rightarrow \text{Flutter Ingestion}$$
*   **Sampling Interval:** 100ms periodic intervals managed via `Util_constructClock` Software Interrupts (Swi).
*   **Data Representation Alert:** The MCU uses **Little Endian** byte formatting (least significant byte first). The Flutter client must reorder bytes using bitwise operations:
    ```dart
    int rawValue = byteList[0] | (byteList[1] << 8);
    ```

---

### 6. Flutter Architecture
*   **Flutter Project Location:** `C:\Users\Devdutt Pandey\smart_house_ble`
*   **State Management:** `Provider` framework managing localized states:
    *   [DeviceProvider](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/state/device/device_provider.dart): Tracks discovered devices and updates their capabilities.
    *   [ConnectionProvider](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/state/connection/connection_provider.dart): Tracks scanning, active connection numbers, and BLE logs.
    *   [BleManagerProvider](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/state/ble/ble_manager_provider.dart): Proxy wrapper coordinating presentation layers and [BleManager](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/services/ble_manager.dart).
    *   [ThemeProvider](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/state/theme/theme_provider.dart): Handles dark and light modes.
*   **Service Layer Separation:**
    *   [ble_manager.dart](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/services/ble_manager.dart): Controls real-world BLE interfaces.
    *   [mock_ble_service.dart](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/services/mock_ble_service.dart): Simulates telemetry data streams (voltage and battery states) to support UI verification.
*   **Folder Structure:**
    *   `lib/models/`: `smart_device.dart`, `device_capability.dart`, `capability_types.dart`.
    *   `lib/screens/`: `dashboard_screen.dart`.
    *   `lib/services/`: BLE management, network simulators.
    *   `lib/state/`: provider state classes.
    *   `lib/theme/`: styling variables and base definitions.
    *   `lib/widgets/`: reusable cards and gauges.

---

### 7. Current Progress Status

```
FIRMWARE (TI CC2640R2 LaunchPad)
├── BLE Advertising                     [ COMPLETE ]
├── Custom GATT Service                 [ COMPLETE ]
├── LED Actuation Control               [ COMPLETE ]
├── Analog ADC Sampling                [ COMPLETE ]
└── BLE Notifications                  [ COMPLETE ]

SOFTWARE (Flutter Central Client)
├── Architecture & Providers            [ COMPLETE ]
├── Backend abstraction layer           [ COMPLETE ]
├── Mock Simulation Framework           [ COMPLETE ]
├── UI Redesign                         [ IN PROGRESS ]
└── Real BLE Integration                [ PENDING ]
```

---

### 8. Current UI Plan
*   **Aesthetics:** Samsung SmartThings inspired layout. Clean dashboard, dark mode optimization, glassmorphic card overlays, and high contrast accents.
*   **Core UI Components:**
    *   *Dashboard View:* Lists registered nodes.
    *   *Detail Controls Page:* For configuring thresholds and reviewing metrics.
    *   *Voltage Display Card:* Analog level indicators.
    *   *Voltage Graph:* Dynamic line chart rendering telemetry changes.
    *   *Connection Card:* Details signal metrics (RSSI) and connectivity status.
    *   *LED Toggles:* Toggles Characteristic `0xD822` states.
    *   *Portrait Lock:* Constrains viewport to vertical alignments.

---

### 9. Known Technical Decisions
*   **Firmware State:** The firmware is **frozen**. Do not modify files in `C:\TI_WORKSPACE\simple_peripheral` unless performing hardware upgrades.
*   **Telemetry Encoding:** Raw values are 12-bit unsigned counts transmitted in 2-byte little-endian configurations. Reverse byte formats are expected behaviors on generic BLE scanner tools. Endian translations are handled strictly on the mobile client.

---

### 10. Immediate Next Tasks
1.  **UI Polish:** Complete dashboard visual updates (gauges, graphs, responsive grids).
2.  **BLE Integration Migration:** 
    *   Replace [mock_ble_service.dart](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/services/mock_ble_service.dart) streams with real BLE operations.
    *   Implement BLE scanning routines, connect to devices advertising as `Simple Peripheral`, discover custom service `0xD820`, subscribe to notification characteristic `0xD821`, and map write actions to `0xD822`.

---

### 11. Future Expansion Roadmap
*   **Short Term:** Enable multi-node board connections and filters.
*   **Mid Term:** Expand to include additional sensors (touch/temperature) and configure GPIO triggers to toggle relays.
*   **Long Term:** Design custom CC2640R2F layouts, migrate to multi-node BLE mesh networks, and construct BLE-to-Wi-Fi gateway systems.

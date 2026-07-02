# Portfolio Project Description
## IoT-Enabled Smart Household Monitoring and Control System

---

### 1. Project Summary
Designed, engineered, and deployed a full-stack, low-latency **embedded IoT smart household monitoring and control platform**. The architecture bridges local physical sensor telemetry with a mobile controller using Bluetooth Low Energy (BLE). 

*   **Firmware Subsystem:** Implemented on a **Texas Instruments CC2640R2F LaunchPad** microchip running **TI-RTOS**. Custom firmware controls hardware peripherals, interfaces with a 12-bit Analog-to-Digital Converter (ADC) to read sensor voltages, maps data to a custom-defined GATT profile, and handles real-time BLE notifications.
*   **Mobile Controller Subsystem:** A cross-platform **Flutter** application written in **Dart** that operates as the BLE Central node. It establishes connection handshakes, sets Client Characteristic Configuration Descriptors (CCCD) to stream asynchronous sensor notifications, and issues write commands to control board actuators (onboard LEDs) through a responsive dashboard.

---

### 2. Core Features
*   **Real-Time Analog Sensor Telemetry:** Digitizes continuous analog voltage feeds (0V to 3.3V) from a 10k potentiometer using a thread-safe ADC driver, transmitting telemetry updates with low power and high response rates.
*   **Low-Overhead Wireless Protocol (BLE):** Leverages BLE 5.0 protocols to minimize active transmission power envelopes, making the sensor-actuator node appropriate for battery-powered household deployments.
*   **Custom GATT Service Architecture:** Developed a proprietary GATT service layout containing multiple characteristics. Features a 16-bit notification characteristic for ADC telemetry and a 2-byte command characteristic for peripheral control.
*   **Bi-Directional Device Control:** Enables remote user actions on the mobile application to control physical hardware state machines (such as toggling indicators) with near-instantaneous execution.
*   **Reactive App State Management:** Separates network traffic from the UI using the **Provider** pattern, minimizing rendering overhead by updating only changing screen widgets.
*   **Modern Smart-Home Visual Interface:** Integrates a glassmorphic dashboard featuring live voltage gauges, dynamic telemetry curves, and custom device cards designed for high readability.

---

### 3. Technical Stack

*   **Embedded & Firmware:** 
    *   *Language:* Embedded C
    *   *RTOS:* TI-RTOS (Real-Time Operating System)
    *   *SDK:* SimpleLink CC2640R2 SDK (v1.40.00.45+)
    *   *BLE Stack:* TI BLE5 Stack (Peripheral Role)
    *   *Peripherals & Drivers:* TI Drivers (ADC, PIN/GPIO, UART, Clock/Timer)
*   **Mobile & Software:**
    *   *Framework:* Flutter (Cross-platform iOS/Android)
    *   *Language:* Dart
    *   *State Management:* Provider (ChangeNotifier, ProxyProvider)
    *   *Network Protocol:* BLE Central (GATT client interface)

---

### 4. Engineering Challenges Solved

#### A. Custom BLE GATT Service Design & Memory Mapping
*   *Challenge:* Standard BLE profiles did not support concurrent, mixed-data telemetry (16-bit analog float equivalents) and multi-channel hardware commands (`[PERIPHERAL_ID, VALUE]`) without substantial latency.
*   *Solution:* Designed a custom GATT profile ([pot_led_service.h](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/ccs_firmware/pot_led_service.h)) under Service UUID `0xD820`. Defined a read/notify characteristic `0xD821` (2 bytes, little-endian) and a read/write characteristic `0xD822` (2 bytes). This optimized payload packing, reducing BLE packet overhead.

#### B. Thread-Safe ADC Driver & RTOS Event Scheduling
*   *Challenge:* Running high-frequency, blocking analog-to-digital conversions on the main RF Core task caused thread starvation, resulting in dropped connection frames and stack overflows.
*   *Solution:* Integrated a non-blocking RTOS software timer (`Clock_Handle`) configured to trigger at specific intervals. The timer queues an application-level event (`SP_PERIODIC_ADC_EVT`) on the task scheduler, allowing the MCU to complete ADC sampling via the TI Driver API, copy the data to the GATT attributes database, and safely notify the client without interrupting RF stack operations.

#### C. Embedded-to-Mobile Serialization and Byte Order Translation
*   *Challenge:* Mismatches in word length and endianness between the ARM Cortex-M3 microcontroller (little-endian) and mobile processors resulted in garbled voltage readings on the application dashboard.
*   *Solution:* Implemented low-level serialization on the firmware side, transmitting the 12-bit ADC value in a 2-byte package. Developed custom decoder filters in Dart ([ble_manager.dart](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/services/ble_manager.dart)) that reconstruct bytes using bitwise shifts ($Value = Byte_0 + (Byte_1 \ll 8)$) to preserve numeric accuracy.

#### D. Firmware Callback Debugging & Memory Corruption Mitigation
*   *Challenge:* Random hardware exceptions occurred during incoming BLE writes. The BLE protocol task ran context-switched callbacks that modified application-level configurations directly, causing heap corruption.
*   *Solution:* Decoupled GATT callbacks from execution tasks by introducing intermediate message queues. Written parameters are temporarily written to a thread-safe message buffer, and the central application task is notified via an event mask (`SP_POTLED_CHAR_CHANGE_EVT`) to retrieve and execute commands from the task thread context.

---

### 5. Future Scope
*   **Multi-Node Smart Grid Topology:** Scale the central Flutter controller to manage multiple CC2640R2 peripheral nodes concurrently, aggregating household telemetry across multiple rooms.
*   **Distributed Sensor Hub Integration:** Interface supplementary SPI/I2C digital sensors (such as DHT22 temperature/humidity chips, and capacitive touch sensors) to the LaunchPad's GPIO bus.
*   **High-Voltage Control Actuation:** Extend the GPIO control framework to switch external, optocoupled solid-state relays, enabling the application to automate mains appliances.
*   **Centralized Gateway Architecture:** Design a dual-chip gateway combining BLE and Wi-Fi/MQTT (e.g., using an ESP32) to route telemetry streams to cloud dashboards, allowing remote, out-of-home control.

---

### 6. Technical Learning Outcomes
*   **Embedded Real-Time Architectures:** Gained expertise in TI-RTOS multitasking, task scheduling, semaphores, clock events, and thread-safe peripheral hardware interfaces.
*   **Low-Level Protocol Implementation:** Mastered the BLE 5.0 protocol stack, including the GAP/GATT layers, advertising state machines, connection parameters, CCCD subscriptions, and service discovery tables.
*   **Cross-Platform Mobile Engineering:** Designed custom service and state abstraction layers in Flutter, establishing reactive data bindings from asynchronous streams.
*   **System Integration & Debugging:** Developed troubleshooting skills across the hardware-software boundary, utilizing Code Composer Studio (CCS), JTAG debuggers, and mobile logs to diagnose data corruption and memory faults.

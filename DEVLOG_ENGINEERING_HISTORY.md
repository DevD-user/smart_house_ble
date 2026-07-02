# Developer Log: Engineering History & Debugging Journal
## Project: IoT-Enabled Smart Household Monitoring and Control System

This document is a technical development log documenting the architectural design choices, software-hardware boundary bugs, and debugging investigations during the implementation of the smart household system.

---

## 1. Project Development Philosophy

The system design follows four core engineering principles:
*   **Scalable Architecture:** The platform must support dynamic expansions, allowing new sensors (temperature, pressure) and actuators (high-power relays) to be added without modifying the core transmission pipeline.
*   **Low-Power Communication (BLE over Wi-Fi):** Selected Bluetooth Low Energy (BLE) instead of Wi-Fi for the endpoint node to establish a low-power envelope, enabling coin-cell or battery-operated operations in remote household locations.
*   **Decoupled Subsystems:** Maintained a clean separation between the firmware (GATT database, hardware drivers, RTOS events) and the frontend (state notification pipelines, graphics view controllers) to simplify parallel development.
*   **Multi-Board Topology:** Designed the communication layer and data structures (such as arrays prefixing peripheral IDs) to support routing telemetry from multiple physical peripheral boards to a single mobile central client.

---

## 2. Initial Firmware Development Stage

The target firmware is developed on the **Texas Instruments CC2640R2 LaunchPad** running the **TI-RTOS** kernel.
1.  **Baseline Project Selection:** Selected the `simple_peripheral` baseline project from the **SimpleLink CC2640R2 SDK (v1.40.00.45)**.
2.  **Environment Setup:** Imported the project targets (`app` and `stack` configurations) into **Code Composer Studio (CCS) v9+** to compile the BLE stack and application code.
3.  **Radio Check:** Confirmed the radio advertising system by flashing the baseline build. The LaunchPad successfully advertised its presence, which was validated via packet sniffers and mobile discovery as:
    *   *Advertised Name:* `Simple Peripheral`
    *   *System Status:* Active advertising loops in low-power sleep states.

---

## 3. Custom BLE Service Development

To handle system telemetry and command operations, a custom GATT profile was designed:
*   **Files:** Created [pot_led_service.h](file:///c:/Users/Devdutt Pandey/smart_house_ble/ccs_firmware/pot_led_service.h) and [pot_led_service.c](file:///c:/Users/Devdutt Pandey/smart_house_ble/ccs_firmware/pot_led_service.c).
*   **Primary Service UUID:** `48c5d820-ac2a-11e7-abc4-cec278b6b50a` (Short ID: `0xD820`).
*   **Characteristic 1 (`POTLED_ADC_VALUE`):**
    *   *UUID:* `48c5d821-ac2a-11e7-abc4-cec278b6b50a` (Short ID: `0xD821`)
    *   *Properties:* `GATT_PROP_READ | GATT_PROP_NOTIFY`
    *   *Data Length:* 2 Bytes (`uint16_t`)
    *   *Purpose:* Real-time streaming of raw 12-bit ADC data representing voltage levels.
*   **Characteristic 2 (`POTLED_LED_STATE`):**
    *   *UUID:* `48c5d822-ac2a-11e7-abc4-cec278b6b50a` (Short ID: `0xD822`)
    *   *Properties:* `GATT_PROP_READ | GATT_PROP_WRITE`
    *   *Data Length:* 2 Bytes (`[PERIPHERAL_ID, VALUE]`)
    *   *Purpose:* Receiver for remote actuator commands.
*   **Callback Interlock:** Registered custom profile callbacks (`potLedServiceCBs_t`) inside the central application loop to safely route GATT events to the task task handler.

---

## 4. LED Control Development Debugging

### The Problem
During development, the mobile client could successfully write commands to Characteristic `0xD822` (returning `GATT_SUCCESS` packets), but the CC2640R2 LaunchPad's onboard LEDs did not toggle.

### Investigation Path
1.  **Callback Tracing:** Inserted breakpoints inside the write attribute callback handler (`potLedService_WriteAttrCB`). The callback fired correctly, and the raw payload was written to `potLedAttrTbl`.
2.  **Queue Validation:** Confirmed that the callback successfully called `SimplePeripheral_enqueueMsg(SP_POTLED_CHAR_CHANGE_EVT, paramID)`, indicating the event was enqueued onto the RTOS message queue.
3.  **Task Dequeue Verification:** Placed debugger highlights inside `SimplePeripheral_processPotLedCharValue()`. The task successfully dequeued the message, but the data parsed from `PotLedService_GetParameter()` was corrupt.

### The Bug
Inside `pot_led_service.c`, the `GetParameter()` routine had a casting error when retrieving the LED state:

```c
// BUGGY CODE (Original)
case POTLED_LED_STATE:
  *((uint8*)value) = potLedLedVal[0];  // Only copies the first byte (peripheral ID)
  break;
```

Because `potLedLedVal` is a 2-byte structure `[PERIPHERAL_ID, VALUE]`, casting the destination pointer `value` to a single byte `uint8_t*` truncated the command byte (`VALUE`), preventing the GPIO pin from receiving the state update.

### The Fix
Modified `PotLedService_GetParameter` to copy the complete array length using memory copy utilities:

```c
// FIXED CODE (Modified)
case POTLED_LED_STATE:
  memcpy(value, potLedLedVal, POTLED_LED_LEN); // Copies the full 2-byte packet
  break;
```

### Result
Commands written to the LED characteristic successfully process both bytes, enabling control of the physical Red and Green LEDs.

---

## 5. ADC Integration Development

To capture real-time potentiometer values, we integrated the TI-RTOS ADC driver:
1.  **Pin Allocation:** Bound analog signal line `DIO23` to driver channel `Board_ADC0` in the LaunchPad's system board layout.
2.  **Driver Initialization:**
    ```c
    ADC_init();
    ADC_Params_init(&params);
    adc = ADC_open(Board_ADC0, &params);
    ```
3.  **Periodic Sampling Scheduler:**
    *   Constructed a periodic RTOS clock struct (`ClkAdc`) utilizing the system tick utility:
        ```c
        Clock_construct(&periodicAdcClock, 
                        SimplePeripheral_clockHandler, 
                        adcPeriodMs * (1000 / Clock_tickPeriod), 
                        adcPeriodMs * (1000 / Clock_tickPeriod), 
                        FALSE, 
                        (UArg)SP_PERIODIC_ADC_EVT);
        ```
    *   Configured a 100ms timer interval to trigger the software interrupt (Swi), queueing `SP_PERIODIC_ADC_EVT`.
    *   Implemented `SimplePeripheral_performAdcSample()` to execute conversions, write results to Characteristic `0xD821`, and close the ADC block to conserve battery power.

---

## 6. ADC Debugging Phase

### The Problem
After configuring the ADC drivers and starting the periodic clock, the analog voltage values displayed on the BLE scanner remained static (typically at `0.0V` or `0x0000`). Rotating the physical potentiometer wiper pin had no effect.

### Investigation Path
1.  **Hardware Connections:** Checked hardware pins with an oscilloscope. Rotating the potentiometer correctly shifted the signal wiper voltage between 0V and 3.3V on physical pin `DIO23`.
2.  **Driver Setup:** Checked `ADC_open` status; it returned a valid handle, indicating the driver was successfully allocated.
3.  **Scheduler Analysis:** Placed breakpoints inside `SimplePeripheral_performAdcSample()`. The breakpoint was never hit, indicating the ADC conversions were not executing.
4.  **Timer Checking:** Confirmed that `Clock_start()` was called during the `GAPROLE_CONNECTED` transition, and the hardware clock interrupts were firing.

### The Bug
While the clock interrupt was firing, the message dispatcher routine was discarding the message. The clock handler was enqueuing `SP_PERIODIC_ADC_EVT` onto the task queue, but the task event loop was not processing the event.

```c
// BUGGY EVENT LOOP (Original simple_peripheral.c clock dispatcher)
// The clock handler was enqueuing the event, but the SWI/Task transition lacked the event mapping.
```

### The Fix
Added a condition in the clock handler processing section inside `SimplePeripheral_clockHandler()` or the task handler thread (`SimplePeripheral_processAppMsg` switch case) to check for the periodic ADC event:

```c
// FIXED DISPATCHER (Added event handling branch)
else if (pData->event == SP_PERIODIC_ADC_EVT)
{
  SimplePeripheral_enqueueMsg(SP_PERIODIC_ADC_EVT, 0);
}
```

And mapped the case within `SimplePeripheral_processAppMsg()`:
```c
case SP_PERIODIC_ADC_EVT:
  SimplePeripheral_performAdcSample();
  break;
```

### Result
The RTOS task loop successfully schedules and processes periodic ADC conversions every 100ms, streaming potentiometer readings to the BLE central client.

---

## 7. BLE Data Interpretation Investigation

### The Problem
During integration tests, the BLE scanner received unexpected byte streams for the ADC characteristic:
*   Expected voltage value: `~1.3V` (approx. `1600` counts, or `0x0640` hexadecimal).
*   Received byte array values: `0xFA0B` or `0x1805`.

### Investigation & Root Cause
1.  **ADC Calibration:** Read raw register registers directly. The ADC was performing correctly, reading accurate digital conversions (e.g., `3066` counts).
2.  **Data Encoding:** Inspected how `PotLedService_SetParameter` saved values. The firmware writes `uint16_t` values directly into the attribute buffer.
3.  **Endianness Analysis:** The CC2640R2 microcontroller is built on an ARM Cortex-M3 core, which processes data in **Little Endian** format (lowest byte stored first). 
    *   *Received Data:* `0xFA0B`
    *   *Byte Reordering:* `0x0B` (high byte) and `0xFA` (low byte) $\rightarrow$ `0x0BFA`.
    *   *Decimal Conversion:* `0x0BFA` = `3066` raw counts.
    *   *Voltage Calculation:*
        $$\text{Voltage} = \frac{3066}{4095} \times 3.3\text{V} \approx 2.47\text{V}$$

### The Solution
The firmware was transmitting data correctly. To fix the display values, the Flutter application must reconstruct the incoming byte streams using little-endian byte ordering:
```dart
// Byte reconstruction logic in Dart
int rawVal = byteList[0] | (byteList[1] << 8);
double voltage = (rawVal / 4095.0) * 3.3;
```

---

## 8. Flutter Architecture Development

The companion mobile application is built using Flutter and Dart, prioritizing decoupled architecture patterns:
*   **State Management:** Implemented utilizing the `Provider` library to decouple UI components from network states.
    *   `DeviceProvider`: Maintains in-memory models of discovered nodes.
    *   `ConnectionProvider`: Tracks scanning and active network logs.
    *   `BleManagerProvider`: Interfaces between presentation states and lower services.
*   **Service Decoupling:** Separated lower-level network APIs from state controllers:
    *   [ble_manager.dart](file:///c:/Users/Devdutt Pandey/smart_house_ble/lib/services/ble_manager.dart): Manages real Bluetooth radios.
    *   [mock_ble_service.dart](file:///c:/Users/Devdutt%20Pandey/smart_house_ble/lib/services/mock_ble_service.dart): Simulates telemetry data streams (voltage and battery states) to support UI verification without physical hardware attached.

---

## 9. Current Technical Status

```
FIRMWARE (TI CC2640R2 LaunchPad)
├── BLE Advertising                     [ COMPLETE ] (Advertising as Simple Peripheral)
├── Custom GATT Service                 [ COMPLETE ] (Service 0xD820 successfully registered)
├── LED Actuation Control               [ COMPLETE ] (2-byte commands toggle LED0)
├── Analog ADC Sampling                [ COMPLETE ] (DIO23 wiper voltage sampled at 12-bit resolution)
├── BLE Notifications                  [ COMPLETE ] (Asynchronous streaming via CCCD configuration)
└── Hardware Target Verification        [ COMPLETE ] (Hardware baseline tests verify stability)

SOFTWARE (Flutter Central Client)
├── Application Architecture            [ COMPLETE ] (Decoupled model-service-view pattern)
├── Backend State Abstraction           [ COMPLETE ] (Device, Connection, and Theme Providers active)
├── UI Redesign                         [ IN PROGRESS ] (Integrating modern glassmorphic dashboard views)
└── BLE Integration Pipeline            [ PENDING ] (Migrating mock streaming to live BLE libraries)
```

---

## 10. Major Technical Lessons Learned

*   **Low-Level GATT Structuring:** Configuring appropriate permissions, variable arrays, and descriptor structures (CCCD tables) in GATT attributes arrays.
*   **RTOS Multi-Tasking & SWIs:** Coordinating periodic clock interrupts with main application tasks using non-blocking queues to avoid starving RF core tasks.
*   **Hardware Driver Configuration:** Mapping logical analog identifiers (`Board_ADC0`) to physical pins (`DIO23`) via board board configurations.
*   **Interrupt vs Task Context Decoupling:** Enqueueing callback notifications to task buffers to prevent long operations from executing within interrupt routines.
*   **Cross-Boundary Endianness Alignment:** Standardizing little-endian byte alignments between microcontrollers and mobile processors.
*   **Decoupled State Management:** Structuring state models to dynamically propagate sensor metrics to specific UI cards without resetting the widget tree.

---

## 11. Future Engineering Expansion

*   **Short Term:**
    *   Establish dual-board BLE telemetry links.
    *   Implement device identifier filtering to parse and display multiple incoming BLE nodes.
*   **Mid Term:**
    *   Integrate additional physical digital/analog sensors (such as touch and temperature sensors).
    *   Incorporate high-voltage relay automation circuits triggered by potentiometer voltage thresholds.
*   **Long Term:**
    *   Design a custom, production-ready CC2640R2F board layout.
    *   Transition the topology from point-to-point connections to mesh configurations.
    *   Integrate gateway routing (such as BLE to MQTT over Wi-Fi) to enable remote, out-of-home cloud control.

---

## 12. Engineering Reflection

This project highlights the importance of managing details at the hardware-software boundary. Developing a real-time sensor system requires matching hardware capabilities, firmware drivers, and OS event scheduling with front-end states. 

Solving issues like task starvation, byte order alignment, and callback execution boundaries emphasizes the value of structured testing and clean architecture. The resulting codebase provides a reliable framework for building scalable smart home monitoring networks.

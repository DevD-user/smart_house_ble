# CC2640R2 Launchpad BLE Firmware Setup

This folder contains the Code Composer Studio (CCS) files and instructions to configure your TI CC2640R2 Launchpad to interface with the Flutter application.

---

## Hardware Wiring Guide

Connect your potentiometer to the BoosterPack headers on the CC2640R2 Launchpad:

| Potentiometer Pin | CC2640R2 Launchpad Pin | BoosterPack Header | Description |
|---|---|---|---|
| **VCC** | `3.3V` | J1.1 | Power source (3.3V max) |
| **GND** | `GND` | J2.20 / J1.2 | Reference ground |
| **Signal (Wiper)** | `DIO23` | J1.4 (`Board_ADC0`) | Analog ADC Input channel |

---

## Software Prerequisites

1. **Code Composer Studio (CCS)**: Version 9.0 or newer.
2. **SimpleLink CC2640R2 SDK**: Version 1.40.00.45 or newer.
3. **XDSTools**: Included with the SDK/CCS (for compiler toolchain).

---

## Integration Steps in Code Composer Studio

### 1. Import Simple Peripheral Project
- Open Code Composer Studio.
- Go to `File` -> `Import` -> `C/C++` -> `CCS Projects`.
- Search the SimpleLink CC2640R2 SDK path (typically `C:\ti\simplelink_cc2640r2_sdk_x_xx_xx_xx\examples\rtos\CC2640R2_LAUNCHXL\ble5stack\simple_peripheral`).
- Import the **`simple_peripheral_cc2640r2lp_app`** project.

### 2. Copy the GATT Profile Files
- Copy [pot_led_service.h](file:///c:/Users/devpa/ble_app/ccs_firmware/pot_led_service.h) and [pot_led_service.c](file:///c:/Users/devpa/ble_app/ccs_firmware/pot_led_service.c) from this workspace and paste them into the **`PROFILES`** or **`Application`** folder of your CCS project.

### 3. Modify `simple_peripheral.c`
- Open `Application/simple_peripheral.c` in CCS.
- Integrate the changes shown in [simple_peripheral_mod.c](file:///c:/Users/devpa/ble_app/ccs_firmware/simple_peripheral_mod.c) sequentially matching the steps:
  - Add includes at the top.
  - Insert task event masks.
  - Declare variables, callback functions, and the GATT callback structure.
  - Add PIN initialization, ADC initialization, Service registration, and clock creation inside `SimplePeripheral_init()`.
  - Add events for `SP_PERIODIC_ADC_EVT` and `SP_POTLED_CHAR_CHANGE_EVT` inside `SimplePeripheral_taskFxn()`.
  - Append helper callbacks and the ADC sampling function at the bottom.
  - Start/Stop the periodic clock on `GAPROLE_CONNECTED` / `GAPROLE_WAITING` inside `SimplePeripheral_processStateChangeEvt()`.

### 4. Configure Board Files (ADC Configuration)
To read analog values from pin `DIO23`, we must verify that `Board_ADC0` is mapped correctly in the TI board description files.

#### A. Open `CC2640R2_LAUNCHXL.h`
Find the `CC2640R2_LAUNCHXL_ADCName` enumeration and ensure it contains `CC2640R2_LAUNCHXL_ADC0`:
```c
typedef enum CC2640R2_LAUNCHXL_ADCName {
    CC2640R2_LAUNCHXL_ADC0 = 0, // Maps to DIO23
    CC2640R2_LAUNCHXL_ADC1,
    CC2640R2_LAUNCHXL_ADCCOUNT
} CC2640R2_LAUNCHXL_ADCName;
```

#### B. Open `CC2640R2_LAUNCHXL.c`
1. Locate the `adcCC26XXHWAttrs` table. Verify that `CC2640R2_LAUNCHXL_ADC0` is configured to map to `PIN_23` (which is `DIO23`):
   ```c
   const ADCDataCC26XX_HWAttrs adcCC26XXHWAttrs[CC2640R2_LAUNCHXL_ADCCOUNT] = {
       {
           .adcPIN = IOID_23,
           .refSource = ADC_COMPB_REF_VDDS_REL,
           .samplingDuration = ADC_COMPB_IN_CAP_MODE_VAL_SYS_DIV_1,
           .inputScalingEnabled = true
       }
   };
   ```
2. Check that the `ADC_config` structure registers this table:
   ```c
   const ADC_Config ADC_config[CC2640R2_LAUNCHXL_ADCCOUNT] = {
       {
           .fxnTablePtr = &ADCCC26XX_fxnTable,
           .object = &adcCC26XXObjects[CC2640R2_LAUNCHXL_ADC0],
           .hwAttrs = &adcCC26XXHWAttrs[CC2640R2_LAUNCHXL_ADC0]
       }
   };
   ```

---

## Compile and Flash

1. Connect your CC2640R2 Launchpad to your PC via a Micro-USB cable.
2. In CCS, right-click the `simple_peripheral_cc2640r2lp_app` project and select **`Rebuild Project`**.
3. Once compiled successfully, click the **`Debug`** icon (bug icon) or right-click -> `Debug As` -> `Code Composer Studio Startup`. This will flash both the stack and the app onto the Launchpad.
4. Hit **`Resume`** (F8 / green play button) to run the code.
5. The device will start advertising as `Simple Peripheral`. Open your Flutter app, scan, connect, and twist your potentiometer to watch the voltage changes!

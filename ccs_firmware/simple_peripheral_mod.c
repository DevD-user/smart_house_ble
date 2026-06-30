/******************************************************************************
 * File: simple_peripheral_mod.c
 *
 * Description: Contains integration instructions and code snippets for modifying
 *              simple_peripheral.c in Code Composer Studio. This incorporates
 *              periodic ADC conversions, custom service registrations, and
 *              LED toggles.
 *****************************************************************************/

/*
 ==============================================================================
 STEP 1: Add Includes
 Place these includes near the top of simple_peripheral.c
 ==============================================================================
*/
#include <ti/drivers/ADC.h>
#include <ti/drivers/PIN.h>
#include "Board.h"
#include "pot_led_service.h"


/*
 ==============================================================================
 STEP 2: Define Task Event Constants
 Place these macro definitions near other SP_... event macros
 ==============================================================================
*/
#define SP_PERIODIC_ADC_EVT            0x0008  // Bitmask for periodic ADC event
#define SP_POTLED_CHAR_CHANGE_EVT      0x0010  // Bitmask for GATT write event


/*
 ==============================================================================
 STEP 3: Declare Global and Static Variables
 Add these declarations with other application variable declarations
 ==============================================================================
*/
// LED PIN Configuration Handle & State
static PIN_Handle ledPinHandle;
static PIN_State  ledPinState;

// Pin Configuration Table (default LED0 on CC2640R2 Launchpad is DIO6)
static PIN_Config potLedPinTable[] = {
    Board_PIN_LED0 | PIN_GPIO_OUTPUT_EN | PIN_GPIO_LOW | PIN_PUSHPULL | PIN_DRVSTR_MAX,
    PIN_TERMINATE
};

// Periodic clock for ADC reading
static Clock_Struct periodicAdcClock;

// Callback function declarations
static void SimplePeripheral_potLedChangeCB(uint8 paramID);
static void SimplePeripheral_performAdcSample(void);
static void SimplePeripheral_processPotLedCharValue(uint8 paramID);

// GATT Service Callbacks
static potLedServiceCBs_t SimplePeripheral_potLedCBs =
{
  SimplePeripheral_potLedChangeCB // Characteristic change callback
};


/*
 ==============================================================================
 STEP 4: Modify SimplePeripheral_init()
 Add these initializations inside the SimplePeripheral_init() function
 ==============================================================================
*/
static void SimplePeripheral_init(void)
{
  // ... [Existing SimplePeripheral init code] ...

  // Initialize PIN driver and open LED pins
  ledPinHandle = PIN_open(&ledPinState, potLedPinTable);
  if (!ledPinHandle) {
    // Pin opening error
  }

  // Initialize TI-RTOS ADC Driver
  ADC_init();

  // Register our Custom GATT Service
  PotLedService_AddService();

  // Register application callbacks with the Custom Service
  PotLedService_RegisterAppCBs(&SimplePeripheral_potLedCBs);

  // Construct periodic clock for ADC conversions (triggers every 100ms)
  // 100ms is converted to ticks based on clock tick period (typically 10us)
  uint32_t adcPeriodMs = 100;
  Clock_construct(&periodicAdcClock, 
                  SimplePeripheral_clockHandler, // Reuses existing Clock SWI handler
                  adcPeriodMs * (1000 / Clock_tickPeriod), 
                  adcPeriodMs * (1000 / Clock_tickPeriod), 
                  FALSE, 
                  (UArg)SP_PERIODIC_ADC_EVT);

  // ... [Remaining SimplePeripheral init code] ...
}


/*
 ==============================================================================
 STEP 5: Add Event Handlers to SimplePeripheral_processAppMsg()
 Add these event handling cases inside the switch-case of SimplePeripheral_processAppMsg()
 ==============================================================================
*/
static void SimplePeripheral_processAppMsg(spEvt_t *pMsg)
{
  switch (pMsg->hdr.event)
  {
    // ... [Existing switch cases like SP_STATE_CHANGE_EVT, etc.] ...

    // Handle Periodic ADC Event
    case SP_PERIODIC_ADC_EVT:
      SimplePeripheral_performAdcSample();
      break;

    // Handle Custom GATT Write Event
    case SP_POTLED_CHAR_CHANGE_EVT:
      SimplePeripheral_processPotLedCharValue(pMsg->hdr.state);
      break;

    default:
      break;
  }
}


/*
 ==============================================================================
 STEP 6: Implement Helper Functions
 Append these functions to the bottom of simple_peripheral.c
 ==============================================================================
*/

/*********************************************************************
 * @fn      SimplePeripheral_potLedChangeCB
 *
 * @brief   Callback from the GATT Profile indicating a characteristic value
 *          has been written by the client.
 */
static void SimplePeripheral_potLedChangeCB(uint8 paramID)
{
  // Enqueue event to process write safely in task context (prevent SWI block)
  SimplePeripheral_enqueueMsg(SP_POTLED_CHAR_CHANGE_EVT, paramID);
}

/*********************************************************************
 * @fn      SimplePeripheral_processPotLedCharValue
 *
 * @brief   Processes a characteristic write event from the application loop.
 */
static void SimplePeripheral_processPotLedCharValue(uint8 paramID)
{
  if (paramID == POTLED_LED_STATE)
  {
    uint8_t commandPacket[2] = {0};

    // Retrieve BLE command packet
    PotLedService_GetParameter(POTLED_LED_STATE, commandPacket);

    uint8_t peripheralId = commandPacket[0];
    uint8_t commandValue = commandPacket[1];

    switch (peripheralId)
    {
      case 1:
        // Red LED
        PIN_setOutputValue(
          ledPinHandle,
          Board_PIN_LED0,
          commandValue
        );
        break;

      case 2:
        // Future Green LED support
        break;

      default:
        break;
    }
  }
}
/*********************************************************************
 * @fn      SimplePeripheral_performAdcSample
 *
 * @brief   Opens ADC driver, performs single-channel conversion, 
 *          closes ADC, and writes value to GATT server.
 */
static void SimplePeripheral_performAdcSample(void)
{
  ADC_Handle adc;
  ADC_Params params;
  uint16_t adcRawValue = 0;

  ADC_Params_init(&params);
  
  // Open Board_ADC0 channel (mapped to DIO23 pin)
  adc = ADC_open(Board_ADC0, &params);

  if (adc != NULL)
  {
    // Block and convert single sample
    int_fast16_t res = ADC_convert(adc, &adcRawValue);

    if (res == ADC_STATUS_SUCCESS)
    {
      // Write raw 12-bit ADC value (0-4095) to the GATT profile
      // This will automatically fire notifications if the client subscribed
      PotLedService_SetParameter(POTLED_ADC_VALUE, POTLED_ADC_LEN, &adcRawValue);
    }
    
    // Close to conserve battery power
    ADC_close(adc);
  }
}


/*
 ==============================================================================
 STEP 7: Manage Timer Based on Connection State
 Inside SimplePeripheral_processStateChangeEvt(), find BLE connection 
 states and start/stop the periodic clock.
 ==============================================================================
*/
static void SimplePeripheral_processStateChangeEvt(gaprole_States_t newState)
{
  switch ( newState )
  {
    case GAPROLE_CONNECTED:
      // Start the clock when client connects
      Clock_start(Clock_handle(&periodicAdcClock));
      break;

    case GAPROLE_WAITING:
    case GAPROLE_WAITING_AFTER_TIMEOUT:
      // Stop the clock and turn off LED on disconnection
      Clock_stop(Clock_handle(&periodicAdcClock));
      PIN_setOutputValue(ledPinHandle, Board_PIN_LED0, 0);
      break;

    default:
      break;
  }
}

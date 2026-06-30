/******************************************************************************
 * File: pot_led_service.h
 *
 * Description: Header file for the custom BLE service interface on TI
 *              CC2640R2 SimpleLink SDK. Defines GATT profile UUIDs,
 *              parameters, and function prototypes.
 *****************************************************************************/

#ifndef POT_LED_SERVICE_H
#define POT_LED_SERVICE_H

#ifdef __cplusplus
extern "C"
{
#endif

/*********************************************************************
 * INCLUDES
 */
#include <bcomdef.h>

/*********************************************************************
 * CONSTANTS
 */
// Custom Profile Service UUID: 48c5d820-ac2a-11e7-abc4-cec278b6b50a
#define POT_LED_SERVICE_SERV_UUID            0xD820

// Custom Characteristic UUIDs
// Characteristic 1: ADC/Voltage Value (Read & Notify): 48c5d821-ac2a-11e7-abc4-cec278b6b50a
#define POT_LED_SERVICE_ADC_CHAR_UUID         0xD821
// Characteristic 2: LED State (Read & Write): 48c5d822-ac2a-11e7-abc4-cec278b6b50a
#define POT_LED_SERVICE_LED_CHAR_UUID         0xD822

// Key profile parameters (used in SetParameter / GetParameter)
#define POTLED_ADC_VALUE                     0
#define POTLED_LED_STATE                     1

// Profile characteristic value lengths
#define POTLED_ADC_LEN                       2  // uint16_t (0-4095 raw value)
#define POTLED_LED_LEN                       1  // uint8_t (0x00=OFF, 0x01=ON)

/*********************************************************************
 * TYPEDEFS
 */

// Callback structure when a characteristic value changes
typedef void (*potLedServiceChange_t)(uint8 paramID);

typedef struct
{
  potLedServiceChange_t pfnChangeCb;  // Pointer to change callback function
} potLedServiceCBs_t;

/*********************************************************************
 * API FUNCTIONS
 */

/*
 * PotLedService_AddService - Initializes the PotLed service by registering
 *          GATT attributes with the GATT server.
 */
extern bStatus_t PotLedService_AddService(void);

/*
 * PotLedService_RegisterAppCBs - Registers the application callback function.
 *          Only call this function once.
 *
 *    appCallbacks - pointer to application callbacks
 */
extern bStatus_t PotLedService_RegisterAppCBs(potLedServiceCBs_t *appCallbacks);

/*
 * PotLedService_SetParameter - Set a PotLed service parameter.
 *
 *    param - Profile parameter ID
 *    len - length of data to right
 *    value - pointer to data to write. This is dependent on
 *          the parameter ID and WILL be cast to the appropriate
 *          data type (e.g. data type of param, uint16, etc.)
 */
extern bStatus_t PotLedService_SetParameter(uint8 param, uint8 len, void *value);

/*
 * PotLedService_GetParameter - Get a PotLed service parameter.
 *
 *    param - Profile parameter ID
 *    value - pointer to data to read. This is dependent on
 *          the parameter ID and WILL be cast to the appropriate
 *          data type (e.g. data type of param, uint16, etc.)
 */
extern bStatus_t PotLedService_GetParameter(uint8 param, void *value);

#ifdef __cplusplus
}
#endif

#endif /* POT_LED_SERVICE_H */

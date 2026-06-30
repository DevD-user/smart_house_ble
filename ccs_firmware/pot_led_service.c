/******************************************************************************
 * File: pot_led_service.c
 *
 * Description: Implementation of the custom BLE service for TI CC2640R2 Launchpad.
 *              Registers GATT attribute tables, handles BLE read and write 
 *              requests, and fires application notifications.
 *****************************************************************************/

/*********************************************************************
 * INCLUDES
 */
#include <string.h>
#include <icall.h>
#include "util.h"
#include "icall_ble_api.h"
/* This Header is from SimpleLink BLE Stack */
#include "gattservapp.h"

#include "pot_led_service.h"

/*********************************************************************
 * MACROS
 */

/*********************************************************************
 * CONSTANTS
 */

/*********************************************************************
 * TYPEDEFS
 */

/*********************************************************************
 * GLOBAL VARIABLES
 */
// PotLed Service UUID: 48c5d820-ac2a-11e7-abc4-cec278b6b50a
static const uint8 potLedServUUID[ATT_UUID_SIZE] =
{
  0x0a, 0xb5, 0xb6, 0x78, 0xc2, 0xce, 0xc4, 0xab, 0xe7, 0x11, 0x2a, 0xac, 0x20, 0xd8, 0xc5, 0x48
};

// ADC Characteristic UUID: 48c5d821-ac2a-11e7-abc4-cec278b6b50a
static const uint8 potLedAdcUUID[ATT_UUID_SIZE] =
{
  0x0a, 0xb5, 0xb6, 0x78, 0xc2, 0xce, 0xc4, 0xab, 0xe7, 0x11, 0x2a, 0xac, 0x21, 0xd8, 0xc5, 0x48
};

// LED Characteristic UUID: 48c5d822-ac2a-11e7-abc4-cec278b6b50a
static const uint8 potLedLedUUID[ATT_UUID_SIZE] =
{
  0x0a, 0xb5, 0xb6, 0x78, 0xc2, 0xce, 0xc4, 0xab, 0xe7, 0x11, 0x2a, 0xac, 0x22, 0xd8, 0xc5, 0x48
};

/*********************************************************************
 * LOCAL VARIABLES
 */

static potLedServiceCBs_t *pAppCBs = NULL;

/*********************************************************************
 * Profile Attributes - Variables
 */

// Service declaration
static const gattAttrType_t potLedServiceDecl = { ATT_UUID_SIZE, potLedServUUID };

// Characteristic 1: ADC/Voltage properties (Read & Notify)
static uint8 potLedAdcProps = GATT_PROP_READ | GATT_PROP_NOTIFY;
// Characteristic 1 Value (2-bytes raw ADC)
static uint8 potLedAdcVal[POTLED_ADC_LEN] = { 0, 0 };
// Client Characteristic Configuration Descriptor (CCCD) for ADC notifications
static gattCharCfg_t *potLedAdcConfigTable;

// Characteristic 2: LED properties (Read & Write)
static uint8 potLedLedProps = GATT_PROP_READ | GATT_PROP_WRITE;
// Characteristic 2 Value (1-byte LED State)
static uint8 potLedLedVal[POTLED_LED_LEN] = { 0 };

/*********************************************************************
 * Profile Attributes - Table
 */

static gattAttribute_t potLedAttrTbl[] =
{
  // 1. Primary Service Declaration
  {
    { ATT_BT_UUID_SIZE, primaryServiceUUID },
    GATT_PERMIT_READ,
    0,
    (uint8 *)&potLedServiceDecl
  },

    // 2. ADC Characteristic Declaration
    {
      { ATT_BT_UUID_SIZE, characterUUID },
      GATT_PERMIT_READ,
      0,
      &potLedAdcProps
    },
      // 3. ADC Characteristic Value
      {
        { ATT_UUID_SIZE, potLedAdcUUID },
        GATT_PERMIT_READ,
        0,
        potLedAdcVal
      },
      // 4. ADC Client Characteristic Configuration Descriptor (CCCD)
      {
        { ATT_BT_UUID_SIZE, clientCharCfgUUID },
        GATT_PERMIT_READ | GATT_PERMIT_WRITE,
        0,
        (uint8 *)&potLedAdcConfigTable
      },

    // 5. LED Characteristic Declaration
    {
      { ATT_BT_UUID_SIZE, characterUUID },
      GATT_PERMIT_READ,
      0,
      &potLedLedProps
    },
      // 6. LED Characteristic Value
      {
        { ATT_UUID_SIZE, potLedLedUUID },
        GATT_PERMIT_READ | GATT_PERMIT_WRITE,
        0,
        potLedLedVal
      }
};

/*********************************************************************
 * LOCAL FUNCTIONS
 */
static bStatus_t potLedService_ReadAttrCB(uint16 connHandle, gattAttribute_t *pAttr,
                                         uint8 *pValue, uint16 *pLen, uint16 offset,
                                         uint16 maxLen, uint8 method);
static bStatus_t potLedService_WriteAttrCB(uint16 connHandle, gattAttribute_t *pAttr,
                                          uint8 *pValue, uint16 len, uint16 offset,
                                          uint8 method);

/*********************************************************************
 * PROFILE CALLBACKS
 */

// Service Callbacks Structure
const gattServiceCBs_t potLedServiceCBs =
{
  potLedService_ReadAttrCB,  // Read callback handler
  potLedService_WriteAttrCB, // Write callback handler
  NULL                       // Authorization callback (not used)
};

/*********************************************************************
 * PUBLIC FUNCTIONS
 */

/*
 * PotLedService_AddService - Registers attributes with the GATT Server.
 */
bStatus_t PotLedService_AddService(void)
{
  uint8 status;

  // Allocate Client Characteristic Configuration Table for notifications
  potLedAdcConfigTable = (gattCharCfg_t *)ICall_malloc(sizeof(gattCharCfg_t) * linkDBNumConns);
  if (potLedAdcConfigTable == NULL)
  {
    return (bleMemAllocError);
  }

  // Initialize Client Characteristic Configuration Table
  GATTServApp_InitCharCfg(CONNHANDLE_INVALID, potLedAdcConfigTable);

  // Register profile with GATT Server App
  status = GATTServApp_RegisterService(potLedAttrTbl, 
                                       GATT_NUM_ATTRS(potLedAttrTbl),
                                       GATT_MAX_ENCRYPT_KEY_SIZE,
                                       &potLedServiceCBs);

  return (status);
}

/*
 * PotLedService_RegisterAppCBs - Registers application callbacks.
 */
bStatus_t PotLedService_RegisterAppCBs(potLedServiceCBs_t *appCallbacks)
{
  if (appCallbacks)
  {
    pAppCBs = appCallbacks;
    return (SUCCESS);
  }
  return (bleAlreadyInRequestedMode);
}

/*
 * PotLedService_SetParameter - Sets service parameter value.
 */
bStatus_t PotLedService_SetParameter(uint8 param, uint8 len, void *value)
{
  bStatus_t status = SUCCESS;
  switch (param)
  {
    case POTLED_ADC_VALUE:
      if (len == POTLED_ADC_LEN)
      {
        memcpy(potLedAdcVal, value, POTLED_ADC_LEN);

        // Try sending notification to connected clients if enabled
        status = GATTServApp_ProcessCharCfg(potLedAdcConfigTable, potLedAdcVal, FALSE,
                                            potLedAttrTbl, GATT_NUM_ATTRS(potLedAttrTbl),
                                            INVALID_TASK_ID, potLedService_ReadAttrCB);
      }
      else
      {
        status = bleInvalidRange;
      }
      break;

    case POTLED_LED_STATE:
      if (len == POTLED_LED_LEN)
      {
       memcpy(potLedLedVal, value, POTLED_LED_LEN);
      }
      else
      {
        status = bleInvalidRange;
      }
      break;

    default:
      status = INVALIDPARAMETER;
      break;
  }

  return (status);
}

/*
 * PotLedService_GetParameter - Gets service parameter value.
 */
bStatus_t PotLedService_GetParameter(uint8 param, void *value)
{
  bStatus_t status = SUCCESS;
  switch (param)
  {
    case POTLED_ADC_VALUE:
      memcpy(value, potLedAdcVal, POTLED_ADC_LEN);
      break;

    case POTLED_LED_STATE:
      *((uint8*)value) = potLedLedVal[0];
      break;

    default:
      status = INVALIDPARAMETER;
      break;
  }

  return (status);
}

/*********************************************************************
 * @fn          potLedService_ReadAttrCB
 *
 * @brief       Read attribute callback handler.
 */
static bStatus_t potLedService_ReadAttrCB(uint16 connHandle, gattAttribute_t *pAttr,
                                         uint8 *pValue, uint16 *pLen, uint16 offset,
                                         uint16 maxLen, uint8 method)
{
  bStatus_t status = SUCCESS;

  // Make sure it's not a long read (our values are short, offsets should be 0)
  if (offset > 0)
  {
    return (ATT_ERR_ATTR_NOT_LONG);
  }

  if (pAttr->type.len == ATT_UUID_SIZE)
  {
    // Compare custom 128-bit UUIDs
    if (memcmp(pAttr->type.uuid, potLedAdcUUID, ATT_UUID_SIZE) == 0)
    {
      *pLen = POTLED_ADC_LEN;
      memcpy(pValue, pAttr->pValue, POTLED_ADC_LEN);
    }
    else if (memcmp(pAttr->type.uuid, potLedLedUUID, ATT_UUID_SIZE) == 0)
    {
      *pLen = POTLED_LED_LEN;
      pValue[0] = pAttr->pValue[0];
    }
    else
    {
      *pLen = 0;
      status = ATT_ERR_ATTR_NOT_FOUND;
    }
  }
  else if (pAttr->type.len == ATT_BT_UUID_SIZE)
  {
    // 16-bit UUIDs (such as Client Characteristic Configuration Descriptor)
    uint16 uuid = BUILD_UINT16(pAttr->type.uuid[0], pAttr->type.uuid[1]);
    switch (uuid)
    {
      case GATT_CLIENT_CHAR_CFG_UUID:
        *pLen = 2;
        pValue[0] = LO_UINT16(GATTServApp_ReadCharCfg(connHandle, potLedAdcConfigTable));
        pValue[1] = HI_UINT16(GATTServApp_ReadCharCfg(connHandle, potLedAdcConfigTable));
        break;

      default:
        *pLen = 0;
        status = ATT_ERR_ATTR_NOT_FOUND;
        break;
    }
  }
  else
  {
    *pLen = 0;
    status = ATT_ERR_INVALID_HANDLE;
  }

  return (status);
}

/*********************************************************************
 * @fn          potLedService_WriteAttrCB
 *
 * @brief       Write attribute callback handler.
 */
static bStatus_t potLedService_WriteAttrCB(uint16 connHandle, gattAttribute_t *pAttr,
                                          uint8 *pValue, uint16 len, uint16 offset,
                                          uint8 method)
{
  bStatus_t status = SUCCESS;
  uint8 notifyApp = 0xFF;

  if (pAttr->type.len == ATT_BT_UUID_SIZE)
  {
    // 16-bit UUID (such as Client Characteristic Configuration Descriptor)
    uint16 uuid = BUILD_UINT16(pAttr->type.uuid[0], pAttr->type.uuid[1]);
    switch (uuid)
    {
      case GATT_CLIENT_CHAR_CFG_UUID:
        status = GATTServApp_ProcessCCCWriteReq(connHandle, pAttr, pValue, len,
                                                 offset, GATT_CLIENT_CFG_NOTIFY);
        break;

      default:
        status = ATT_ERR_ATTR_NOT_FOUND;
        break;
    }
  }
  else if (pAttr->type.len == ATT_UUID_SIZE)
  {
    // 128-bit Custom UUIDs
    if (memcmp(pAttr->type.uuid, potLedLedUUID, ATT_UUID_SIZE) == 0)
    {
      // Validate bounds
      if (offset + len > POTLED_LED_LEN)
      {
        status = ATT_ERR_INVALID_OFFSET;
      }
      else if (len != POTLED_LED_LEN)
      {
        status = ATT_ERR_INVALID_VALUE_SIZE;
      }
      else
      {
        uint8 peripheralId = pValue[0];
        uint8 commandValue = pValue[1];

        // Validate packet structure
        if ((peripheralId == 1 || peripheralId == 2) &&
        (commandValue == 0x00 || commandValue == 0x01))
      {
        memcpy(pAttr->pValue, pValue, POTLED_LED_LEN);
        notifyApp = POTLED_LED_STATE;
      }
        else
        {
          status = ATT_ERR_INVALID_VALUE;
        }
      }
    }
    else
    {
      status = ATT_ERR_ATTR_NOT_FOUND;
    }
  }
  else
  {
    status = ATT_ERR_INVALID_HANDLE;
  }

  // If a characteristic was successfully written and callbacks are registered, notify the app task
  if ((status == SUCCESS) && (notifyApp != 0xFF) && pAppCBs && pAppCBs->pfnChangeCb)
  {
    pAppCBs->pfnChangeCb(notifyApp);
  }

  return (status);
}

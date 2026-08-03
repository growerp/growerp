---
type: Moqui Entity
title: PayrollAdjCalcService
description: "Payroll Adj Calc Service"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjCalcService
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollAdjCalcService

Payroll Adj Calc Service

Full entity name: `mantle.humanres.employment.PayrollAdjCalcService`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `adjCalcServiceId` | id | Y |  |
| `organizationPartyId` | id |  | If null applies to all organizations |
| `payrollPhaseEnumId` | id |  |  |
| `description` | text-medium |  | Description for the OrderItem (itemDescription), adjustment calc service should run this through ResourceFacade.expand() with parameters depending on the adjustment calc service |
| `serviceRegisterId` | id |  | Registered Service of type PayrollAdjustmentCalc that implements the mantle.humanres.PayrollServices.calculate#Adjustment interface |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.service.ServiceRegister` via `serviceRegisterId`
- many [PayrollAdjCalcParameter](PayrollAdjCalcParameter.md) via `adjCalcServiceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjCalcService

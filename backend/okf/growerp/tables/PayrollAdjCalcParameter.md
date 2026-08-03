---
type: Moqui Entity
title: PayrollAdjCalcParameter
description: "Payroll Adj Calc Parameter"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjCalcParameter
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollAdjCalcParameter

Payroll Adj Calc Parameter

Full entity name: `mantle.humanres.employment.PayrollAdjCalcParameter`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `adjCalcServiceId` | id | Y |  |
| `parameterName` | text-short | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `parameterValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PayrollAdjCalcService](PayrollAdjCalcService.md) via `adjCalcServiceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjCalcParameter

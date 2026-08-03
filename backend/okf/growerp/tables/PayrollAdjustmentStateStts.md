---
type: Moqui Entity
title: PayrollAdjustmentStateStts
description: "Payroll Adjustment State Stts"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustmentStateStts
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollAdjustmentStateStts

Payroll Adjustment State Stts

Full entity name: `mantle.humanres.employment.PayrollAdjustmentStateStts`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payrollAdjustmentId` | id | Y |  |
| `taxStateStatusEnumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PayrollAdjustment](PayrollAdjustment.md) via `payrollAdjustmentId`
- one `moqui.basic.Enumeration` via `taxStateStatusEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustmentStateStts

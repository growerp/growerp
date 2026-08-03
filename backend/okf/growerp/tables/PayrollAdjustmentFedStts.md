---
type: Moqui Entity
title: PayrollAdjustmentFedStts
description: "Payroll Adjustment Fed Stts"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustmentFedStts
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollAdjustmentFedStts

Payroll Adjustment Fed Stts

Full entity name: `mantle.humanres.employment.PayrollAdjustmentFedStts`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payrollAdjustmentId` | id | Y |  |
| `taxFederalStatusEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PayrollAdjustment](PayrollAdjustment.md) via `payrollAdjustmentId`
- one `moqui.basic.Enumeration` via `taxFederalStatusEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustmentFedStts

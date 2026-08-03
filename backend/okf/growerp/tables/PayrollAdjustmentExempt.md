---
type: Moqui Entity
title: PayrollAdjustmentExempt
description: "Payroll Adjustment Exempt"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustmentExempt
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollAdjustmentExempt

Payroll Adjustment Exempt

Full entity name: `mantle.humanres.employment.PayrollAdjustmentExempt`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payrollAdjustmentId` | id | Y |  |
| `taxExemptEnumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PayrollAdjustment](PayrollAdjustment.md) via `payrollAdjustmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustmentExempt

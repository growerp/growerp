---
type: Moqui Entity
title: PayrollAdjustmentDetail
description: "Payroll Adjustment Detail"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustmentDetail
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollAdjustmentDetail

Payroll Adjustment Detail

Full entity name: `mantle.humanres.employment.PayrollAdjustmentDetail`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payrollAdjustmentId` | id | Y |  |
| `detailSeqId` | id | Y |  |
| `rate` | number-float |  |  |
| `rateAfterYtdMin` | text-indicator |  |  |
| `ytdMin` | currency-amount |  |  |
| `ytdMax` | currency-amount |  |  |
| `rateAfterPeriodMin` | text-indicator |  |  |
| `periodMin` | currency-amount |  |  |
| `periodMax` | currency-amount |  |  |
| `flatAmount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PayrollAdjustment](PayrollAdjustment.md) via `payrollAdjustmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAdjustmentDetail

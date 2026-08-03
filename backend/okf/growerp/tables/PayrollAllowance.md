---
type: Moqui Entity
title: PayrollAllowance
description: "Payroll Allowance"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAllowance
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollAllowance

Payroll Allowance

Full entity name: `mantle.humanres.employment.PayrollAllowance`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payrollAllowanceId` | id | Y |  |
| `taxAuthorityId` | id |  |  |
| `timePeriodTypeId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `amountTypeEnumId` | id |  |  |
| `amount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one [TimePeriodType](TimePeriodType.md) via `timePeriodTypeId`
- one `moqui.basic.Enumeration` via `amountTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollAllowance

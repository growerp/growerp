---
type: Moqui Entity
title: PayrollStdDeduction
description: "Payroll Std Deduction"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollStdDeduction
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollStdDeduction

Payroll Std Deduction

Full entity name: `mantle.humanres.employment.PayrollStdDeduction`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payrollStdDeductionId` | id | Y |  |
| `taxAuthorityId` | id |  |  |
| `timePeriodTypeId` | id |  |  |
| `taxFederalStatusEnumId` | id |  |  |
| `taxStateStatusEnumId` | id |  |  |
| `minAllowances` | number-integer |  |  |
| `maxAllowances` | number-integer |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `amount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one [TimePeriodType](TimePeriodType.md) via `timePeriodTypeId`
- one `moqui.basic.Enumeration` via `taxFederalStatusEnumId`
- one `moqui.basic.Enumeration` via `taxStateStatusEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollStdDeduction

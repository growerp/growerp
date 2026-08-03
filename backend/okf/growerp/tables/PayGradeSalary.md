---
type: Moqui Entity
title: PayGradeSalary
description: "Pay Grade Salary"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.rate.PayGradeSalary
tags: [mantle, humanres, rate]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayGradeSalary

Pay Grade Salary

Full entity name: `mantle.humanres.rate.PayGradeSalary`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `payGradeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `amount` | currency-amount |  |  |
| `minAmount` | currency-amount |  |  |
| `maxAmount` | currency-amount |  |  |
| `currencyUomId` | id |  |  |
| `timePeriodTypeId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PayGrade](PayGrade.md) via `payGradeId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [TimePeriodType](TimePeriodType.md) via `timePeriodTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.rate.PayGradeSalary

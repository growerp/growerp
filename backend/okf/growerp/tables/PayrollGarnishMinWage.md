---
type: Moqui Entity
title: PayrollGarnishMinWage
description: "Payroll Garnish Min Wage"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollGarnishMinWage
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PayrollGarnishMinWage

Payroll Garnish Min Wage

Full entity name: `mantle.humanres.employment.PayrollGarnishMinWage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `stateOrCountryGeoId` | id | Y |  |
| `timePeriodTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `minimumWage` | number-decimal |  |  |
| `rangeLow` | number-decimal |  |  |
| `rangeHigh` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Geo` via `stateOrCountryGeoId`
- one [TimePeriodType](TimePeriodType.md) via `timePeriodTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.PayrollGarnishMinWage

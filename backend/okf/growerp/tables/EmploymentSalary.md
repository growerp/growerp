---
type: Moqui Entity
title: EmploymentSalary
description: "The current and past actual salary amounts for Employment. Current salary found by standard date filter and sort (filter by fromDate, thruDate; sort by ascending fromDate; use first result)."
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentSalary
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmploymentSalary

The current and past actual salary amounts for Employment. Current salary found by standard date filter and sort (filter by fromDate, thruDate; sort by ascending fromDate; use first result).

Full entity name: `mantle.humanres.employment.EmploymentSalary`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyRelationshipId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `payGradeId` | id |  |  |
| `comments` | text-medium |  |  |
| `amount` | currency-amount |  |  |
| `currencyUomId` | id |  |  |
| `timePeriodTypeId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Employment](Employment.md) via `partyRelationshipId`
- one [PayGrade](PayGrade.md) via `payGradeId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [TimePeriodType](TimePeriodType.md) via `timePeriodTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.EmploymentSalary

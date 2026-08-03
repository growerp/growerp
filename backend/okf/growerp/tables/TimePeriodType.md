---
type: Moqui Entity
title: TimePeriodType
description: "Time Period Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.time.TimePeriodType
tags: [mantle, party, time]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TimePeriodType

Time Period Type

Full entity name: `mantle.party.time.TimePeriodType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `timePeriodTypeId` | id | Y |  |
| `periodPurposeEnumId` | id |  |  |
| `parentPeriodTypeId` | id |  |  |
| `description` | text-medium |  |  |
| `periodLength` | number-decimal |  |  |
| `lengthUomId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `periodPurposeEnumId`
- one [Parent TimePeriodType](TimePeriodType.md) via `parentPeriodTypeId`
- one `moqui.basic.Uom` via `lengthUomId`
- many [Employment](Employment.md) via `timePeriodTypeId`
- many [EmploymentSalary](EmploymentSalary.md) via `timePeriodTypeId`
- many [PayrollAdjustment](PayrollAdjustment.md) via `timePeriodTypeId`
- many [PayrollAllowance](PayrollAllowance.md) via `timePeriodTypeId`
- many [PayrollGarnishMinWage](PayrollGarnishMinWage.md) via `timePeriodTypeId`
- many [PayrollStdDeduction](PayrollStdDeduction.md) via `timePeriodTypeId`
- many [PayGradeSalary](PayGradeSalary.md) via `timePeriodTypeId`
- many [Hourly PartyAcctgPreference](PartyAcctgPreference.md) via `timePeriodTypeId`
- many [Salary PartyAcctgPreference](PartyAcctgPreference.md) via `timePeriodTypeId`
- many [TimePeriod](TimePeriod.md) via `timePeriodTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.time.TimePeriodType

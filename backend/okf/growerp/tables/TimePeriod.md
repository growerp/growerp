---
type: Moqui Entity
title: TimePeriod
description: "For configurable time periods used in accounting, sales quotas, etc."
resource: http://127.0.0.1:8080/rest/e1/mantle.party.time.TimePeriod
tags: [mantle, party, time]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TimePeriod

For configurable time periods used in accounting, sales quotas, etc.

Full entity name: `mantle.party.time.TimePeriod`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `timePeriodId` | id | Y |  |
| `parentPeriodId` | id |  |  |
| `previousPeriodId` | id |  |  |
| `timePeriodTypeId` | id |  |  |
| `partyId` | id |  | The Party that owns the TimePeriod, generally an Internal Organization. |
| `periodNum` | number-integer |  |  |
| `periodName` | text-medium |  |  |
| `fromDate` | date |  | The first day of the period. |
| `thruDate` | date |  | The last day of the period. |
| `isClosed` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent TimePeriod](TimePeriod.md) via `parentPeriodId`
- one [Previous TimePeriod](TimePeriod.md) via `previousPeriodId`
- one [TimePeriodType](TimePeriodType.md) via `timePeriodTypeId`
- many [Invoice](Invoice.md) via `timePeriodId`
- many [Payment](Payment.md) via `timePeriodId`
- many [EmploymentPayHistory](EmploymentPayHistory.md) via `timePeriodId`
- many [GlAccountOrgTimePeriod](GlAccountOrgTimePeriod.md) via `timePeriodId`
- many [Budget](Budget.md) via `timePeriodId`
- many [Sub BudgetItem](BudgetItem.md) via `timePeriodId`
- many [TaxStatement](TaxStatement.md) via `timePeriodId`
- many [AssetDepreciation](AssetDepreciation.md) via `timePeriodId`
- many [SalesForecast](SalesForecast.md) via `timePeriodId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.time.TimePeriod

---
type: Moqui Entity
title: RateAmount
description: "Rate Amount"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.rate.RateAmount
tags: [mantle, humanres, rate]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RateAmount

Rate Amount

Full entity name: `mantle.humanres.rate.RateAmount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `rateAmountId` | id | Y |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `rateTypeEnumId` | id |  |  |
| `ratePurposeEnumId` | id |  |  |
| `rateCurrencyUomId` | id |  |  |
| `timePeriodUomId` | id |  |  |
| `workEffortId` | id |  |  |
| `partyId` | id |  |  |
| `workTypeEnumId` | id |  |  |
| `payGradeId` | id |  |  |
| `emplPositionClassId` | id |  |  |
| `rateAmount` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `rateTypeEnumId`
- one `moqui.basic.Enumeration` via `ratePurposeEnumId`
- one `moqui.basic.Uom` via `rateCurrencyUomId`
- one `moqui.basic.Uom` via `timePeriodUomId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Party](Party.md) via `partyId`
- one [PayGrade](PayGrade.md) via `payGradeId`
- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one `moqui.basic.Enumeration` via `workTypeEnumId`
- many [TimeEntry](TimeEntry.md) via `rateAmountId`
- many [Vendor TimeEntry](TimeEntry.md) via `rateAmountId`
- many [Piece TimeEntry](TimeEntry.md) via `rateAmountId`
- many [VendorPiece TimeEntry](TimeEntry.md) via `rateAmountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.rate.RateAmount

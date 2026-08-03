---
type: Moqui Entity
title: AssetDepreciation
description: "Asset Depreciation"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetDepreciation
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetDepreciation

Asset Depreciation

Full entity name: `mantle.product.asset.AssetDepreciation`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `timePeriodId` | id | Y |  |
| `monthlyDepreciation` | currency-amount |  |  |
| `annualDepreciation` | currency-amount |  |  |
| `yearBeginDepreciation` | currency-amount |  |  |
| `isLastYearPeriod` | text-indicator |  |  |
| `usefulLifeYears` | number-integer |  |  |
| `yearsRemaining` | number-integer |  |  |
| `acctgTransId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [TimePeriod](TimePeriod.md) via `timePeriodId`
- one [AcctgTrans](AcctgTrans.md) via `acctgTransId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetDepreciation

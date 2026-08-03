---
type: Moqui Entity
title: AssetStandardCost
description: "Asset Standard Cost"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetStandardCost
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetStandardCost

Asset Standard Cost

Full entity name: `mantle.product.asset.AssetStandardCost`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `assetStandardCostTypeEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `amountUomId` | id |  |  |
| `amount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one `moqui.basic.Enumeration` via `assetStandardCostTypeEnumId`
- one `moqui.basic.Uom` via `amountUomId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.AssetStandardCost

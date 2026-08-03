---
type: Moqui Entity
title: AssetMeter
description: "Asset Meter"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetMeter
tags: [mantle, product, maintenance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetMeter

Asset Meter

Full entity name: `mantle.product.maintenance.AssetMeter`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetId` | id | Y |  |
| `readingDate` | date-time | Y |  |
| `productMeterTypeId` | id |  |  |
| `productMeterId` | id |  |  |
| `meterValue` | number-decimal |  |  |
| `readingReasonEnumId` | id |  |  |
| `assetMaintenanceId` | id |  |  |
| `workEffortId` | id |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [AssetMaintenance](AssetMaintenance.md) via `assetMaintenanceId`
- one [ProductMeterType](ProductMeterType.md) via `productMeterTypeId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetMeter

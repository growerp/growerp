---
type: Moqui Entity
title: AssetMaintenance
description: "Asset Maintenance"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetMaintenance
tags: [mantle, product, maintenance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetMaintenance

Asset Maintenance

Full entity name: `mantle.product.maintenance.AssetMaintenance`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetMaintenanceId` | id | Y |  |
| `assetId` | id |  |  |
| `statusId` | id |  |  |
| `maintenanceDate` | date-time |  |  |
| `maintenanceTypeEnumId` | id |  |  |
| `productMaintenanceId` | id |  | Optional, though should be filled in to determine upcoming maintenance for all scheduled maintenance |
| `taskWorkEffortId` | id |  |  |
| `intervalQuantity` | number-decimal |  |  |
| `intervalUomId` | id |  | UOM for intervalQuantity; ignored if intervalProductMeterId is used |
| `intervalProductMeterId` | id |  |  |
| `purchaseOrderId` | id |  |  |
| `userId` | id |  |  |
| `comments` | text-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.Enumeration` via `maintenanceTypeEnumId`
- one [ProductMaintenance](ProductMaintenance.md) via `productMaintenanceId`
- one [Task WorkEffort](WorkEffort.md) via `taskWorkEffortId`
- one `moqui.basic.Uom` via `intervalUomId`
- one [Interval ProductMeter](ProductMeter.md) via `intervalProductMeterId`
- one [Purchase OrderHeader](OrderHeader.md) via `purchaseOrderId`
- one `moqui.security.UserAccount` via `userId`
- many [AssetDetail](AssetDetail.md) via `assetMaintenanceId`
- many [AssetIssuance](AssetIssuance.md) via `assetMaintenanceId`
- many [AssetMaintenanceContent](AssetMaintenanceContent.md) via `assetMaintenanceId`
- many [AssetMaintenanceOrderItem](AssetMaintenanceOrderItem.md) via `assetMaintenanceId`
- many [AssetMeter](AssetMeter.md) via `assetMaintenanceId`
- many [Measurement](Measurement.md) via `assetMaintenanceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetMaintenance

---
type: Moqui Entity
title: AssetMaintenanceOrderItem
description: "Asset Maintenance Order Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetMaintenanceOrderItem
tags: [mantle, product, maintenance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetMaintenanceOrderItem

Asset Maintenance Order Item

Full entity name: `mantle.product.maintenance.AssetMaintenanceOrderItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetMaintenanceId` | id | Y |  |
| `orderId` | id | Y |  |
| `orderItemSeqId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AssetMaintenance](AssetMaintenance.md) via `assetMaintenanceId`
- one [OrderHeader](OrderHeader.md) via `orderId`
- one-nofk [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.AssetMaintenanceOrderItem

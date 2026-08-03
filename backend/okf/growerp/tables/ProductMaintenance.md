---
type: Moqui Entity
title: ProductMaintenance
description: "This is used to specify the details for scheduled maintenance."
resource: http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.ProductMaintenance
tags: [mantle, product, maintenance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ProductMaintenance

This is used to specify the details for scheduled maintenance.

Full entity name: `mantle.product.maintenance.ProductMaintenance`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productMaintenanceId` | id | Y |  |
| `productId` | id |  |  |
| `maintenanceTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `comments` | text-long |  |  |
| `templateWorkEffortId` | id |  | Template of Maintenance Plan. WorkEffort may have WorkEffortAssoc records for tasks/breakdown details. |
| `intervalQuantity` | number-decimal |  |  |
| `intervalProductMeterId` | id |  |  |
| `intervalUomId` | id |  | UOM for intervalQuantity; ignored if intervalProductMeterId is used |
| `repeatCount` | number-integer |  | If 0 or null means no limit to repeat count; can be used with multiple ProductMaintenance records for a single MaintenanceType in cases where maintenance intervals are not evenly distributed, or only need to be done once like a break-in period |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one `moqui.basic.Enumeration` via `maintenanceTypeEnumId`
- one [Template WorkEffort](WorkEffort.md) via `templateWorkEffortId`
- one `moqui.basic.Uom` via `intervalUomId`
- one [Interval ProductMeter](ProductMeter.md) via `intervalProductMeterId`
- many [AssetMaintenance](AssetMaintenance.md) via `productMaintenanceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.maintenance.ProductMaintenance

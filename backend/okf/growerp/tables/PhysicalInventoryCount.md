---
type: Moqui Entity
title: PhysicalInventoryCount
description: "Physical Inventory Count"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.PhysicalInventoryCount
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PhysicalInventoryCount

Physical Inventory Count

Full entity name: `mantle.product.asset.PhysicalInventoryCount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `physicalInventoryCountId` | id | Y |  |
| `physicalInventoryId` | id |  |  |
| `facilityId` | id |  |  |
| `locationSeqId` | id |  |  |
| `productId` | id |  |  |
| `lotId` | id |  |  |
| `countDate` | date-time |  |  |
| `quantityOnHand` | number-decimal |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PhysicalInventory](PhysicalInventory.md) via `physicalInventoryId`
- one [Facility](Facility.md) via `facilityId`
- one-nofk [FacilityLocation](FacilityLocation.md) via `facilityId`, `locationSeqId`
- one [Product](Product.md) via `productId`
- one [Lot](Lot.md) via `lotId`
- many [AssetDetail](AssetDetail.md) via `physicalInventoryCountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.PhysicalInventoryCount

---
type: Moqui Entity
title: PhysicalInventory
description: "Physical Inventory"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.asset.PhysicalInventory
tags: [mantle, product, asset]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PhysicalInventory

Physical Inventory

Full entity name: `mantle.product.asset.PhysicalInventory`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `physicalInventoryId` | id | Y |  |
| `physicalInventoryDate` | date-time |  |  |
| `statusId` | id |  |  |
| `facilityId` | id |  |  |
| `partyId` | id |  |  |
| `comments` | text-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Facility](Facility.md) via `facilityId`
- many [AcctgTrans](AcctgTrans.md) via `physicalInventoryId`
- many [AssetDetail](AssetDetail.md) via `physicalInventoryId`
- many [PhysicalInventoryCount](PhysicalInventoryCount.md) via `physicalInventoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.asset.PhysicalInventory

---
type: Moqui Entity
title: ShipmentItem
description: "Shipment Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentItem
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentItem

Shipment Item

Full entity name: `mantle.shipment.ShipmentItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `productId` | id | Y |  |
| `quantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Shipment](Shipment.md) via `shipmentId`
- one [Product](Product.md) via `productId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `shipmentId`, `productId`
- many [ShipmentPackageContent](ShipmentPackageContent.md) via `shipmentId`, `productId`
- many [AssetIssuance](AssetIssuance.md) via `shipmentId`, `productId`
- many [AssetReceipt](AssetReceipt.md) via `shipmentId`, `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentItem

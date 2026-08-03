---
type: Moqui Entity
title: ShipmentPackageContent
description: "Shipment Package Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentPackageContent
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentPackageContent

Shipment Package Content

Full entity name: `mantle.shipment.ShipmentPackageContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `shipmentPackageSeqId` | id | Y |  |
| `productId` | id | Y |  |
| `quantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one-nofk [Shipment](Shipment.md) via `shipmentId`
- one [ShipmentPackage](ShipmentPackage.md) via `shipmentId`, `shipmentPackageSeqId`
- one [ShipmentItem](ShipmentItem.md) via `shipmentId`, `productId`
- one-nofk [Product](Product.md) via `productId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `shipmentId`, `productId`
- many [ShipmentPackageRouteSeg](ShipmentPackageRouteSeg.md) via `shipmentId`, `shipmentPackageSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentPackageContent

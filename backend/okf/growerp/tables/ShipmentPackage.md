---
type: Moqui Entity
title: ShipmentPackage
description: "Shipment Package"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentPackage
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentPackage

Shipment Package

Full entity name: `mantle.shipment.ShipmentPackage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `shipmentPackageSeqId` | id | Y |  |
| `shipmentBoxTypeId` | id |  |  |
| `weight` | number-decimal |  |  |
| `weightUomId` | id |  |  |
| `gatewayPackageId` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Shipment](Shipment.md) via `shipmentId`
- one [ShipmentBoxType](ShipmentBoxType.md) via `shipmentBoxTypeId`
- one `moqui.basic.Uom` via `weightUomId`
- many [ShipmentPackageContent](ShipmentPackageContent.md) via `shipmentId`, `shipmentPackageSeqId`
- many [ShipmentPackageRouteSeg](ShipmentPackageRouteSeg.md) via `shipmentId`, `shipmentPackageSeqId`
- many [AssetReceipt](AssetReceipt.md) via `shipmentId`, `shipmentPackageSeqId`
- many [ShipmentContent](ShipmentContent.md) via `shipmentId`, `shipmentPackageSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentPackage

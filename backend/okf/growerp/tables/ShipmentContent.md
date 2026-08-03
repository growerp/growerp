---
type: Moqui Entity
title: ShipmentContent
description: "Shipment Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentContent
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentContent

Shipment Content

Full entity name: `mantle.shipment.ShipmentContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentContentId` | id | Y |  |
| `shipmentContentTypeEnumId` | id |  |  |
| `shipmentId` | id |  |  |
| `productId` | id |  |  |
| `shipmentPackageSeqId` | id |  |  |
| `shipmentRouteSegmentSeqId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `shipmentContentTypeEnumId`
- one [Shipment](Shipment.md) via `shipmentId`
- one [Product](Product.md) via `productId`
- one-nofk [ShipmentPackage](ShipmentPackage.md) via `shipmentId`, `shipmentPackageSeqId`
- one-nofk [ShipmentRouteSegment](ShipmentRouteSegment.md) via `shipmentId`, `shipmentRouteSegmentSeqId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentContent

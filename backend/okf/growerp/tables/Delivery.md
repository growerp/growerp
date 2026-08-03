---
type: Moqui Entity
title: Delivery
description: "Delivery"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.Delivery
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Delivery

Delivery

Full entity name: `mantle.shipment.carrier.Delivery`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `deliveryId` | id | Y |  |
| `originFacilityId` | id |  |  |
| `destFacilityId` | id |  |  |
| `actualStartDate` | date-time |  |  |
| `actualArrivalDate` | date-time |  |  |
| `estimatedStartDate` | date-time |  |  |
| `estimatedArrivalDate` | date-time |  |  |
| `assetId` | id |  |  |
| `startMileage` | number-decimal |  |  |
| `endMileage` | number-decimal |  |  |
| `fuelUsed` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [Origin Facility](Facility.md) via `originFacilityId`
- one [Dest Facility](Facility.md) via `destFacilityId`
- many [ShipmentRouteSegment](ShipmentRouteSegment.md) via `deliveryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.Delivery

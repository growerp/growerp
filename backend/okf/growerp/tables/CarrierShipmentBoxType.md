---
type: Moqui Entity
title: CarrierShipmentBoxType
description: "Carrier Shipment Box Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.CarrierShipmentBoxType
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CarrierShipmentBoxType

Carrier Shipment Box Type

Full entity name: `mantle.shipment.carrier.CarrierShipmentBoxType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `carrierPartyId` | id | Y |  |
| `shipmentBoxTypeId` | id | Y |  |
| `packagingTypeCode` | id |  |  |
| `oversizeCode` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ShipmentBoxType](ShipmentBoxType.md) via `shipmentBoxTypeId`
- one [Carrier Party](Party.md) via `carrierPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.CarrierShipmentBoxType

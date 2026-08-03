---
type: Moqui Entity
title: ShipmentContactMech
description: "Shipment Contact Mech"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentContactMech
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentContactMech

Shipment Contact Mech

Full entity name: `mantle.shipment.ShipmentContactMech`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `contactMechPurposeId` | id | Y |  |
| `contactMechId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Shipment](Shipment.md) via `shipmentId`
- one [ContactMechPurpose](ContactMechPurpose.md) via `contactMechPurposeId`
- one [ContactMech](ContactMech.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentContactMech

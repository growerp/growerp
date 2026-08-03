---
type: Moqui Entity
title: ShipmentParty
description: "Shipment Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentParty
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentParty

Shipment Party

Full entity name: `mantle.shipment.ShipmentParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Shipment](Shipment.md) via `shipmentId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentParty

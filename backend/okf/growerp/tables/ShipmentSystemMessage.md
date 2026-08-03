---
type: Moqui Entity
title: ShipmentSystemMessage
description: "Shipment System Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentSystemMessage
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentSystemMessage

Shipment System Message

Full entity name: `mantle.shipment.ShipmentSystemMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `systemMessageId` | id | Y |  |
| `externalId` | text-short |  |  |
| `originId` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Shipment](Shipment.md) via `shipmentId`
- one `moqui.service.message.SystemMessage` via `systemMessageId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentSystemMessage

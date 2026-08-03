---
type: Moqui Entity
title: ShipmentEmailMessage
description: "Shipment Email Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentEmailMessage
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentEmailMessage

Shipment Email Message

Full entity name: `mantle.shipment.ShipmentEmailMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `emailMessageId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Shipment](Shipment.md) via `shipmentId`
- one `moqui.basic.email.EmailMessage` via `emailMessageId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentEmailMessage

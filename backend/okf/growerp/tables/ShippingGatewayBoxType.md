---
type: Moqui Entity
title: ShippingGatewayBoxType
description: "Use to override gatewayBoxId on ShipmentBoxType"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayBoxType
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShippingGatewayBoxType

Use to override gatewayBoxId on ShipmentBoxType

Full entity name: `mantle.shipment.carrier.ShippingGatewayBoxType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shippingGatewayConfigId` | id | Y |  |
| `shipmentBoxTypeId` | id | Y |  |
| `gatewayBoxId` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ShippingGatewayConfig](ShippingGatewayConfig.md) via `shippingGatewayConfigId`
- one [ShipmentBoxType](ShipmentBoxType.md) via `shipmentBoxTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayBoxType

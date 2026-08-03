---
type: Moqui Entity
title: ShippingGatewayMethod
description: "Use to override gatewayServiceCode on CarrierShipmentMethod"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayMethod
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShippingGatewayMethod

Use to override gatewayServiceCode on CarrierShipmentMethod

Full entity name: `mantle.shipment.carrier.ShippingGatewayMethod`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shippingGatewayConfigId` | id | Y |  |
| `carrierPartyId` | id | Y |  |
| `shipmentMethodEnumId` | id | Y |  |
| `gatewayServiceCode` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ShippingGatewayConfig](ShippingGatewayConfig.md) via `shippingGatewayConfigId`
- one [Carrier Party](Party.md) via `carrierPartyId`
- one `moqui.basic.Enumeration` via `shipmentMethodEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayMethod

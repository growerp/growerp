---
type: Moqui Entity
title: ShippingGatewayCarrier
description: "Shipping Gateway Carrier"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayCarrier
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShippingGatewayCarrier

Shipping Gateway Carrier

Full entity name: `mantle.shipment.carrier.ShippingGatewayCarrier`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shippingGatewayConfigId` | id | Y |  |
| `carrierPartyId` | id | Y |  |
| `gatewayAccountId` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ShippingGatewayConfig](ShippingGatewayConfig.md) via `shippingGatewayConfigId`
- one [Carrier Party](Party.md) via `carrierPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayCarrier

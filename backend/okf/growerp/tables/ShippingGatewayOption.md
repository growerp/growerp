---
type: Moqui Entity
title: ShippingGatewayOption
description: "Shipping Gateway Option"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayOption
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShippingGatewayOption

Shipping Gateway Option

Full entity name: `mantle.shipment.carrier.ShippingGatewayOption`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shippingGatewayConfigId` | id | Y |  |
| `optionEnumId` | id | Y |  |
| `optionValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ShippingGatewayConfig](ShippingGatewayConfig.md) via `shippingGatewayConfigId`
- one `moqui.basic.Enumeration` via `optionEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayOption

---
type: Moqui Entity
title: CarrierShipmentMethod
description: "Carrier Shipment Method"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.CarrierShipmentMethod
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CarrierShipmentMethod

Carrier Shipment Method

Full entity name: `mantle.shipment.carrier.CarrierShipmentMethod`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `carrierPartyId` | id | Y |  |
| `shipmentMethodEnumId` | id | Y |  |
| `description` | text-medium |  |  |
| `sequenceNum` | number-integer |  |  |
| `carrierServiceCode` | text-short |  |  |
| `scaCode` | text-short |  | Standard Carrier Alpha Code |
| `gatewayServiceCode` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Carrier Party](Party.md) via `carrierPartyId`
- one `moqui.basic.Enumeration` via `shipmentMethodEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.CarrierShipmentMethod

---
type: Moqui Entity
title: ShipmentBoxType
description: "Shipment Box Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentBoxType
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentBoxType

Shipment Box Type

Full entity name: `mantle.shipment.ShipmentBoxType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentBoxTypeId` | id | Y |  |
| `pseudoId` | text-short |  |  |
| `description` | text-medium |  |  |
| `dimensionUomId` | id |  |  |
| `boxLength` | number-decimal |  |  |
| `boxWidth` | number-decimal |  |  |
| `boxHeight` | number-decimal |  |  |
| `weightUomId` | id |  |  |
| `boxWeight` | number-decimal |  |  |
| `defaultGrossWeight` | number-decimal |  | For flat rate boxes up to a certain weight, used if there is no ShipmentPackage.weight |
| `capacityUomId` | id |  |  |
| `boxCapacity` | number-decimal |  |  |
| `gatewayBoxId` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Uom` via `dimensionUomId`
- one `moqui.basic.Uom` via `weightUomId`
- one `moqui.basic.Uom` via `capacityUomId`
- many [FacilityBoxType](FacilityBoxType.md) via `shipmentBoxTypeId`
- many [Default Product](Product.md) via `shipmentBoxTypeId`
- many [Asset](Asset.md) via `shipmentBoxTypeId`
- many [ShipmentPackage](ShipmentPackage.md) via `shipmentBoxTypeId`
- many [CarrierShipmentBoxType](CarrierShipmentBoxType.md) via `shipmentBoxTypeId`
- many [ShippingGatewayBoxType](ShippingGatewayBoxType.md) via `shipmentBoxTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentBoxType

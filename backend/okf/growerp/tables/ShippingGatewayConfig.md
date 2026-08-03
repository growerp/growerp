---
type: Moqui Entity
title: ShippingGatewayConfig
description: "Shipping Gateway Config"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayConfig
tags: [mantle, shipment, carrier]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShippingGatewayConfig

Shipping Gateway Config

Full entity name: `mantle.shipment.carrier.ShippingGatewayConfig`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shippingGatewayConfigId` | id | Y |  |
| `shippingGatewayTypeEnumId` | id |  | Each shipping gateway integration should define a ShippingGatewayType Enumeration record plus an entity with a shared PK (ie PK is shippingGatewayConfigId). |
| `description` | text-medium |  |  |
| `getOrderRateServiceName` | text-medium |  | Service implementing mantle.shipment.CarrierServices.get#OrderShippingRate interface. |
| `getShippingRatesBulkName` | text-medium |  | Service implementing mantle.shipment.CarrierServices.get#ShippingRatesBulk interface. |
| `getAutoPackageInfoName` | text-medium |  | Service implementing mantle.shipment.CarrierServices.get#AutoPackageInfo interface. |
| `getRateServiceName` | text-medium |  | Service implementing mantle.shipment.CarrierServices.get#ShippingRate interface. |
| `requestLabelsServiceName` | text-medium |  | Service implementing mantle.shipment.CarrierServices.request#ShippingLabels interface. |
| `refundLabelsServiceName` | text-medium |  | Service implementing mantle.shipment.CarrierServices.refund#ShippingLabels interface. |
| `trackLabelsServiceName` | text-medium |  | Service implementing mantle.shipment.CarrierServices.track#ShippingLabels interface. |
| `validateAddressServiceName` | text-medium |  | Service implementing mantle.shipment.CarrierServices.validate#ShippingPostalAddress interface. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `shippingGatewayTypeEnumId`
- many [ShippingGatewayBoxType](ShippingGatewayBoxType.md) via `shippingGatewayConfigId`
- many [ShippingGatewayCarrier](ShippingGatewayCarrier.md) via `shippingGatewayConfigId`
- many [ShippingGatewayMethod](ShippingGatewayMethod.md) via `shippingGatewayConfigId`
- many [ShippingGatewayOption](ShippingGatewayOption.md) via `shippingGatewayConfigId`
- many [ProductStoreShippingGateway](ProductStoreShippingGateway.md) via `shippingGatewayConfigId`
- many [ShipmentRouteSegment](ShipmentRouteSegment.md) via `shippingGatewayConfigId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.carrier.ShippingGatewayConfig

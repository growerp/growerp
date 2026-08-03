---
type: Moqui Entity
title: ShipmentRouteSegment
description: "Shipment Route Segment"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentRouteSegment
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentRouteSegment

Shipment Route Segment

Full entity name: `mantle.shipment.ShipmentRouteSegment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `shipmentRouteSegmentSeqId` | id | Y |  |
| `deliveryId` | id |  |  |
| `shippingGatewayConfigId` | id |  |  |
| `originFacilityId` | id |  |  |
| `originPostalContactMechId` | id |  |  |
| `originTelecomContactMechId` | id |  |  |
| `returnPostalContactMechId` | id |  |  |
| `destinationFacilityId` | id |  |  |
| `destPostalContactMechId` | id |  |  |
| `destTelecomContactMechId` | id |  |  |
| `carrierPartyId` | id |  |  |
| `shipmentMethodEnumId` | id |  |  |
| `tradeTermEnumId` | id |  |  |
| `customsCertify` | text-indicator |  |  |
| `customsCertifySigner` | text-short |  |  |
| `customsContentsEnumId` | id |  |  |
| `customsNonDeliveryEnumId` | id |  |  |
| `statusId` | id |  |  |
| `carrierDeliveryZone` | text-short |  |  |
| `carrierRestrictionCodes` | text-short |  |  |
| `carrierRestrictionDesc` | text-very-long |  |  |
| `billingWeight` | number-decimal |  |  |
| `billingWeightUomId` | id |  |  |
| `actualTransportCost` | currency-amount |  |  |
| `actualServiceCost` | currency-amount |  |  |
| `actualOtherCost` | currency-amount |  |  |
| `actualCost` | currency-amount |  |  |
| `costUomId` | id |  |  |
| `actualStartDate` | date-time |  |  |
| `actualArrivalDate` | date-time |  |  |
| `estimatedStartDate` | date-time |  |  |
| `estimatedArrivalDate` | date-time |  |  |
| `masterTrackingCode` | text-medium |  |  |
| `masterTrackingUrl` | text-long |  |  |
| `homeDeliveryType` | id |  |  |
| `homeDeliveryDate` | date-time |  |  |
| `thirdPartyAccountNumber` | id |  |  |
| `thirdPartyPostalCode` | id |  |  |
| `thirdPartyCountryGeoCode` | id |  |  |
| `highValueReport` | binary-very-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Shipment](Shipment.md) via `shipmentId`
- one [Delivery](Delivery.md) via `deliveryId`
- one [ShippingGatewayConfig](ShippingGatewayConfig.md) via `shippingGatewayConfigId`
- one [Carrier Party](Party.md) via `carrierPartyId`
- one `moqui.basic.Enumeration` via `shipmentMethodEnumId`
- one `moqui.basic.Enumeration` via `tradeTermEnumId`
- one `moqui.basic.Enumeration` via `customsContentsEnumId`
- one `moqui.basic.Enumeration` via `customsNonDeliveryEnumId`
- one [Origin Facility](Facility.md) via `originFacilityId`
- one-nofk [Origin ContactMech](ContactMech.md) via `originPostalContactMechId`
- one [Origin PostalAddress](PostalAddress.md) via `originPostalContactMechId`
- one-nofk [Origin ContactMech](ContactMech.md) via `originTelecomContactMechId`
- one [Origin TelecomNumber](TelecomNumber.md) via `originTelecomContactMechId`
- one-nofk [Return ContactMech](ContactMech.md) via `returnPostalContactMechId`
- one [Return PostalAddress](PostalAddress.md) via `returnPostalContactMechId`
- one [Destination Facility](Facility.md) via `destinationFacilityId`
- one-nofk [Destination ContactMech](ContactMech.md) via `destPostalContactMechId`
- one [Destination PostalAddress](PostalAddress.md) via `destPostalContactMechId`
- one-nofk [Destination ContactMech](ContactMech.md) via `destTelecomContactMechId`
- one [Destination TelecomNumber](TelecomNumber.md) via `destTelecomContactMechId`
- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.Uom` via `costUomId`
- one `moqui.basic.Uom` via `billingWeightUomId`
- many [ShipmentPackageRouteSeg](ShipmentPackageRouteSeg.md) via `shipmentId`, `shipmentRouteSegmentSeqId`
- many [ShipmentContent](ShipmentContent.md) via `shipmentId`, `shipmentRouteSegmentSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentRouteSegment

---
type: Moqui Entity
title: ShipmentPackageRouteSeg
description: "Shipment Package Route Seg"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentPackageRouteSeg
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentPackageRouteSeg

Shipment Package Route Seg

Full entity name: `mantle.shipment.ShipmentPackageRouteSeg`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentId` | id | Y |  |
| `shipmentPackageSeqId` | id | Y |  |
| `shipmentRouteSegmentSeqId` | id | Y |  |
| `trackingCode` | text-medium |  |  |
| `trackingUrl` | text-intermediate |  |  |
| `trackingStatusEnumId` | id |  |  |
| `trackingSubStatus` | text-short |  |  |
| `trackingStatusDate` | date-time |  |  |
| `trackingEta` | date-time |  |  |
| `trackingOrigEta` | date-time |  |  |
| `boxNumber` | text-short |  |  |
| `labelDate` | date-time |  |  |
| `labelUrl` | text-intermediate |  |  |
| `labelImage` | binary-very-long |  |  |
| `labelIntlSignImage` | binary-very-long |  |  |
| `labelHtml` | text-very-long |  |  |
| `labelPrinted` | text-indicator |  |  |
| `internationalInvoice` | binary-very-long |  |  |
| `internationalInvoiceUrl` | text-intermediate |  |  |
| `gatewayStatus` | text-short |  |  |
| `gatewayMessage` | text-medium |  |  |
| `gatewayLabelId` | text-short |  |  |
| `gatewayRateId` | text-short |  |  |
| `gatewayRefundId` | text-short |  |  |
| `gatewayRefundStatus` | text-short |  |  |
| `returnTrackingCode` | text-medium |  |  |
| `returnTrackingUrl` | text-intermediate |  |  |
| `returnTrackingStatusEnumId` | id |  |  |
| `returnTrackingSubStatus` | text-short |  |  |
| `returnTrackingStatusDate` | date-time |  |  |
| `returnLabelDate` | date-time |  |  |
| `returnLabelUrl` | text-intermediate |  |  |
| `returnLabelImage` | binary-very-long |  |  |
| `returnIntlInvoiceUrl` | text-intermediate |  |  |
| `returnGatewayStatus` | text-short |  |  |
| `returnGatewayMessage` | text-medium |  |  |
| `returnGatewayLabelId` | text-short |  |  |
| `returnGatewayRateId` | text-short |  |  |
| `returnGatewayRefundStatus` | text-short |  |  |
| `returnEstimatedAmount` | currency-amount |  |  |
| `returnBaseAmount` | currency-amount |  |  |
| `returnActualAmount` | currency-amount |  |  |
| `estimatedAmount` | currency-amount |  |  |
| `baseAmount` | currency-amount |  |  |
| `actualAmount` | currency-amount |  |  |
| `packageTransportAmount` | currency-amount |  |  |
| `packageServiceAmount` | currency-amount |  |  |
| `packageOtherAmount` | currency-amount |  |  |
| `codAmount` | currency-amount |  |  |
| `insuranceAmount` | currency-amount |  | Usually an estimate: insuredAmount * (ProductStoreShippingGateway.insurancePercent/100) |
| `insuredAmount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one-nofk [Shipment](Shipment.md) via `shipmentId`
- one [ShipmentPackage](ShipmentPackage.md) via `shipmentId`, `shipmentPackageSeqId`
- one [ShipmentRouteSegment](ShipmentRouteSegment.md) via `shipmentId`, `shipmentRouteSegmentSeqId`
- one `moqui.basic.Enumeration` via `trackingStatusEnumId`
- one `moqui.basic.Enumeration` via `returnTrackingStatusEnumId`
- many [ShipmentPackageContent](ShipmentPackageContent.md) via `shipmentId`, `shipmentPackageSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentPackageRouteSeg

---
type: Moqui Entity
title: AssetIssuance
description: "Asset Issuance"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.issuance.AssetIssuance
tags: [mantle, product, issuance]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetIssuance

Asset Issuance

Full entity name: `mantle.product.issuance.AssetIssuance`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetIssuanceId` | id | Y |  |
| `assetId` | id |  |  |
| `assetReservationId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `shipmentId` | id |  |  |
| `shipmentItemSourceId` | id |  |  |
| `productId` | id |  |  |
| `invoiceId` | id |  |  |
| `invoiceItemSeqId` | id |  |  |
| `returnId` | id |  |  |
| `returnItemSeqId` | id |  |  |
| `workEffortId` | id |  |  |
| `facilityId` | id |  |  |
| `assetMaintenanceId` | id |  |  |
| `issuedByUserId` | id |  |  |
| `issuedDate` | date-time |  |  |
| `quantity` | number-decimal |  |  |
| `quantityCancelled` | number-decimal |  |  |
| `acctgTransResultEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one-nofk [AssetReservation](AssetReservation.md) via `assetReservationId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [Shipment](Shipment.md) via `shipmentId`
- one-nofk [ShipmentItem](ShipmentItem.md) via `shipmentId`, `productId`
- one [ShipmentItemSource](ShipmentItemSource.md) via `shipmentItemSourceId`
- one-nofk [Invoice](Invoice.md) via `invoiceId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [ReturnItem](ReturnItem.md) via `returnId`, `returnItemSeqId`
- one [Product](Product.md) via `productId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [Facility](Facility.md) via `facilityId`
- one [AssetMaintenance](AssetMaintenance.md) via `assetMaintenanceId`
- many [WorkEffortProduct](WorkEffortProduct.md) via `workEffortId`, `productId`
- one `moqui.security.UserAccount` via `issuedByUserId`
- one `moqui.basic.Enumeration` via `acctgTransResultEnumId`
- many [AcctgTrans](AcctgTrans.md) via `assetIssuanceId`
- many [OrderItemBilling](OrderItemBilling.md) via `assetIssuanceId`
- many [AssetDetail](AssetDetail.md) via `assetIssuanceId`
- many [AssetIssuanceParty](AssetIssuanceParty.md) via `assetIssuanceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.issuance.AssetIssuance

---
type: Moqui Entity
title: AssetReceipt
description: "Asset Receipt"
resource: http://127.0.0.1:8080/rest/e1/mantle.product.receipt.AssetReceipt
tags: [mantle, product, receipt]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssetReceipt

Asset Receipt

Full entity name: `mantle.product.receipt.AssetReceipt`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assetReceiptId` | id | Y |  |
| `assetId` | id |  |  |
| `productId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `shipmentId` | id |  |  |
| `shipmentItemSourceId` | id |  |  |
| `shipmentPackageSeqId` | id |  |  |
| `invoiceId` | id |  |  |
| `invoiceItemSeqId` | id |  |  |
| `returnId` | id |  |  |
| `returnItemSeqId` | id |  |  |
| `workEffortId` | id |  |  |
| `receivedByUserId` | id |  |  |
| `receivedDate` | date-time |  |  |
| `itemDescription` | text-medium |  |  |
| `quantityAccepted` | number-decimal |  |  |
| `quantityRejected` | number-decimal |  |  |
| `rejectionReasonEnumId` | id |  |  |
| `acctgTransResultEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Asset](Asset.md) via `assetId`
- one [Product](Product.md) via `productId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [Shipment](Shipment.md) via `shipmentId`
- one [ShipmentItemSource](ShipmentItemSource.md) via `shipmentItemSourceId`
- one-nofk [ShipmentItem](ShipmentItem.md) via `shipmentId`, `productId`
- one-nofk [ShipmentPackage](ShipmentPackage.md) via `shipmentId`, `shipmentPackageSeqId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [ReturnItem](ReturnItem.md) via `returnId`, `returnItemSeqId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- many [WorkEffortProduct](WorkEffortProduct.md) via `workEffortId`, `productId`
- one `moqui.security.UserAccount` via `receivedByUserId`
- one `moqui.basic.Enumeration` via `rejectionReasonEnumId`
- one `moqui.basic.Enumeration` via `acctgTransResultEnumId`
- many [AcctgTrans](AcctgTrans.md) via `assetReceiptId`
- many [OrderItemBilling](OrderItemBilling.md) via `assetReceiptId`
- many [ReturnItemBilling](ReturnItemBilling.md) via `assetReceiptId`
- many [AssetDetail](AssetDetail.md) via `assetReceiptId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.product.receipt.AssetReceipt

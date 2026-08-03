---
type: Moqui Entity
title: ShipmentItemSource
description: "Shipment Item Source"
resource: http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentItemSource
tags: [mantle, shipment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ShipmentItemSource

Shipment Item Source

Full entity name: `mantle.shipment.ShipmentItemSource`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `shipmentItemSourceId` | id | Y |  |
| `shipmentId` | id |  |  |
| `productId` | id |  |  |
| `binLocationNumber` | number-integer |  | This overrides the corresponding Shipment.binLocationNumber so that a shipment may be split across picklist bins, such as when one bin per order on the shipment is needed. |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `returnId` | id |  |  |
| `returnItemSeqId` | id |  |  |
| `statusId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `quantityNotHandled` | number-decimal |  |  |
| `quantityPicked` | number-decimal |  |  |
| `invoiceId` | id |  |  |
| `invoiceItemSeqId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one-nofk [Shipment](Shipment.md) via `shipmentId`
- one [ShipmentItem](ShipmentItem.md) via `shipmentId`, `productId`
- one [Product](Product.md) via `productId`
- one-nofk [OrderHeader](OrderHeader.md) via `orderId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [ReturnHeader](ReturnHeader.md) via `returnId`
- one `moqui.basic.StatusItem` via `statusId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- many [ReturnItem](ReturnItem.md) via `returnId`, `returnItemSeqId`
- many [AssetIssuance](AssetIssuance.md) via `shipmentItemSourceId`
- many [AssetReceipt](AssetReceipt.md) via `shipmentItemSourceId`
- many [ShipmentPackageContent](ShipmentPackageContent.md) via `shipmentId`, `productId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.shipment.ShipmentItemSource

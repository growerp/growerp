---
type: Moqui Entity
title: OrderItemBilling
description: "Order Item Billing"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.OrderItemBilling
tags: [mantle, order]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OrderItemBilling

Order Item Billing

Full entity name: `mantle.order.OrderItemBilling`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `orderItemBillingId` | id | Y |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `invoiceId` | id |  |  |
| `invoiceItemSeqId` | id |  |  |
| `assetIssuanceId` | id |  |  |
| `assetReceiptId` | id |  |  |
| `shipmentId` | id |  | For physical items the assetIssuanceId can be used to find the Shipment but for adjustments and such, possibly prorated for a particular Shipment, this is the way to find it. |
| `quantity` | number-decimal |  |  |
| `amount` | currency-precise |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [AssetReceipt](AssetReceipt.md) via `assetReceiptId`
- one [AssetIssuance](AssetIssuance.md) via `assetIssuanceId`
- one [Shipment](Shipment.md) via `shipmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.OrderItemBilling

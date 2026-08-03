---
type: Moqui Entity
title: ReturnItem
description: "Return Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnItem
tags: [mantle, order, return]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ReturnItem

Return Item

Full entity name: `mantle.order.return.ReturnItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `returnId` | id | Y |  |
| `returnItemSeqId` | id | Y |  |
| `parentItemSeqId` | id |  |  |
| `returnReasonEnumId` | id |  |  |
| `returnResponseEnumId` | id |  |  |
| `responseImmediate` | text-indicator |  | Process response immediately (Y) or wait for returned inventory (N) |
| `itemTypeEnumId` | id |  |  |
| `productId` | id |  |  |
| `replacementProductId` | id |  |  |
| `description` | text-medium |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `statusId` | id |  |  |
| `inventoryStatusId` | id |  | If specified the status of received inventory (for resell, damaged, etc) |
| `returnQuantity` | number-decimal |  | Quantity promised by customer |
| `receivedQuantity` | number-decimal |  | Quantity actually received from customer |
| `returnPrice` | currency-amount |  |  |
| `responseAmount` | currency-amount |  | Total response amount, independent of quantity. Manually set before response processes to use the given amount, otherwise calculated during process response from received/return quantity * returnPrice (defaults to OrderItem.unitAmount) |
| `externalId` | text-short |  | ID for the return item in the direct upstream system it came from if it came from an external system |
| `responseDate` | date-time |  |  |
| `replacementOrderId` | id |  |  |
| `finAccountTransId` | id |  |  |
| `refundPaymentId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ReturnHeader](ReturnHeader.md) via `returnId`
- one-nofk [Parent ReturnItem](ReturnItem.md) via `returnId`, `parentItemSeqId`
- many [Child ReturnItem](ReturnItem.md) via `returnId`, `returnItemSeqId`
- one `moqui.basic.Enumeration` via `returnReasonEnumId`
- one `moqui.basic.Enumeration` via `returnResponseEnumId`
- one `moqui.basic.Enumeration` via `itemTypeEnumId`
- one-nofk [OrderHeader](OrderHeader.md) via `orderId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one `moqui.basic.StatusItem` via `statusId`
- one `moqui.basic.StatusItem` via `inventoryStatusId`
- one [Product](Product.md) via `productId`
- one [Replacement Product](Product.md) via `replacementProductId`
- one [Replacement OrderHeader](OrderHeader.md) via `replacementOrderId`
- one [FinancialAccountTrans](FinancialAccountTrans.md) via `finAccountTransId`
- one [Refund Payment](Payment.md) via `refundPaymentId`
- many [AssetIssuance](AssetIssuance.md) via `returnId`, `returnItemSeqId`
- many [AssetReceipt](AssetReceipt.md) via `returnId`, `returnItemSeqId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `returnId`, `returnItemSeqId`
- many [ReturnItemBilling](ReturnItemBilling.md) via `returnId`, `returnItemSeqId`
- many [AssetDetail](AssetDetail.md) via `returnId`, `returnItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnItem

---
type: Moqui Entity
title: ReturnItemBilling
description: "Return Item Billing"
resource: http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnItemBilling
tags: [mantle, order, return]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ReturnItemBilling

Return Item Billing

Full entity name: `mantle.order.return.ReturnItemBilling`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `returnId` | id | Y |  |
| `returnItemSeqId` | id | Y |  |
| `invoiceId` | id | Y |  |
| `invoiceItemSeqId` | id | Y |  |
| `assetReceiptId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `amount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ReturnItem](ReturnItem.md) via `returnId`, `returnItemSeqId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [AssetReceipt](AssetReceipt.md) via `assetReceiptId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.order.return.ReturnItemBilling

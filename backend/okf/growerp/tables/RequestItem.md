---
type: Moqui Entity
title: RequestItem
description: "Request Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestItem
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestItem

Request Item

Full entity name: `mantle.request.RequestItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestId` | id | Y |  |
| `requestItemSeqId` | id | Y |  |
| `statusId` | id |  |  |
| `requiredByDate` | date-time |  |  |
| `productId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `selectedAmount` | number-decimal |  | When Product.amountRequire=Y the amount goes here to supplement the quantity. |
| `maximumAmount` | currency-amount |  | The maximum amount (price) to pay for the item. |
| `description` | text-medium |  |  |
| `supplierPartyId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Request](Request.md) via `requestId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Product](Product.md) via `productId`
- one [Supplier Party](Party.md) via `supplierPartyId`
- many [RequestItemAssoc](RequestItemAssoc.md) via `requestId`, `requestItemSeqId`
- many [Other RequestItemAssoc](RequestItemAssoc.md) via `requestId`, `requestItemSeqId`
- many [RequestItemOrder](RequestItemOrder.md) via `requestId`, `requestItemSeqId`
- many [RequestNote](RequestNote.md) via `requestId`, `requestItemSeqId`
- many [RequirementRequestItem](RequirementRequestItem.md) via `requestId`, `requestItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestItem

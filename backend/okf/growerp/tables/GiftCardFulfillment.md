---
type: Moqui Entity
title: GiftCardFulfillment
description: "Gift Card Fulfillment"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.GiftCardFulfillment
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GiftCardFulfillment

Gift Card Fulfillment

Full entity name: `mantle.account.method.GiftCardFulfillment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `fulfillmentId` | id | Y |  |
| `typeEnumId` | id |  |  |
| `merchantId` | text-medium |  |  |
| `partyId` | id |  |  |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  |  |
| `surveyResponseId` | id |  |  |
| `cardNumber` | text-medium |  |  |
| `pinNumber` | text-medium |  |  |
| `amount` | currency-amount |  |  |
| `responseCode` | text-short |  |  |
| `referenceNum` | text-short |  |  |
| `authCode` | text-short |  |  |
| `fulfillmentDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `typeEnumId`
- one [Party](Party.md) via `partyId`
- one [OrderHeader](OrderHeader.md) via `orderId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.GiftCardFulfillment

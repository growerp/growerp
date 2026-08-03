---
type: Moqui Entity
title: PaymentContent
description: "Payment Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.payment.PaymentContent
tags: [mantle, account, payment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentContent

Payment Content

Full entity name: `mantle.account.payment.PaymentContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentContentId` | id | Y |  |
| `paymentId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `contentTypeEnumId` | id |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Payment](Payment.md) via `paymentId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.payment.PaymentContent

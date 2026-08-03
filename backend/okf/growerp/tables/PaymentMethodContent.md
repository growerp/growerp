---
type: Moqui Entity
title: PaymentMethodContent
description: "Payment Method Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethodContent
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentMethodContent

Payment Method Content

Full entity name: `mantle.account.method.PaymentMethodContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodContentId` | id | Y |  |
| `paymentMethodId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `contentTypeEnumId` | id |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethodContent

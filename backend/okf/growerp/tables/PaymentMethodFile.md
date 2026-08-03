---
type: Moqui Entity
title: PaymentMethodFile
description: "Payment Method File"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethodFile
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentMethodFile

Payment Method File

Full entity name: `mantle.account.method.PaymentMethodFile`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodFileId` | id | Y |  |
| `paymentMethodId` | id |  |  |
| `fileTypeEnumId` | id |  |  |
| `fileDate` | date-time |  |  |
| `entryCount` | number-integer |  |  |
| `debitAmountTotal` | currency-amount |  |  |
| `creditAmountTotal` | currency-amount |  |  |
| `fileText` | text-very-long |  |  |
| `isCancelled` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one `moqui.basic.Enumeration` via `fileTypeEnumId`
- one-nofk [PaymentMethodFileType](PaymentMethodFileType.md) via `paymentMethodId`, `fileTypeEnumId`
- many [Payment](Payment.md) via `paymentMethodFileId`
- many `moqui.service.message.SystemMessage` via `paymentMethodFileId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethodFile

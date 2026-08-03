---
type: Moqui Entity
title: PaymentMethodFileType
description: "Payment Method File Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethodFileType
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentMethodFileType

Payment Method File Type

Full entity name: `mantle.account.method.PaymentMethodFileType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `fileTypeEnumId` | id | Y |  |
| `systemMessageTypeId` | id |  |  |
| `systemMessageRemoteId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one `moqui.basic.Enumeration` via `fileTypeEnumId`
- one `moqui.service.message.SystemMessageType` via `systemMessageTypeId`
- one `moqui.service.message.SystemMessageRemote` via `systemMessageRemoteId`
- many [PaymentMethodFile](PaymentMethodFile.md) via `paymentMethodId`, `fileTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethodFileType

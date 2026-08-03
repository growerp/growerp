---
type: Moqui Entity
title: PaymentGatewayResponse
description: "Payment Gateway Response"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentGatewayResponse
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentGatewayResponse

Payment Gateway Response

Full entity name: `mantle.account.method.PaymentGatewayResponse`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentGatewayResponseId` | id | Y |  |
| `paymentGatewayConfigId` | id |  |  |
| `paymentOperationEnumId` | id |  |  |
| `paymentId` | id |  |  |
| `paymentMethodId` | id |  |  |
| `finAccountId` | id |  |  |
| `amount` | currency-amount |  |  |
| `amountUomId` | id |  |  |
| `referenceNum` | text-short |  |  |
| `altReference` | text-short |  |  |
| `subReference` | text-short |  |  |
| `approvalCode` | text-short |  |  |
| `responseCode` | text-short |  |  |
| `reasonCode` | text-short |  |  |
| `reasonMessage` | text-medium |  |  |
| `avsResult` | text-short |  |  |
| `cvResult` | text-short |  |  |
| `scoreResult` | text-short |  |  |
| `transactionDate` | date-time |  |  |
| `transactionStatus` | text-short |  |  |
| `resultSuccess` | text-indicator |  |  |
| `resultDeclined` | text-indicator |  |  |
| `resultError` | text-indicator |  |  |
| `resultNsf` | text-indicator |  |  |
| `resultBadExpire` | text-indicator |  |  |
| `resultBadCardNumber` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `paymentOperationEnumId`
- one `moqui.basic.Uom` via `amountUomId`
- one [Payment](Payment.md) via `paymentId`
- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one [FinancialAccount](FinancialAccount.md) via `finAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentGatewayResponse

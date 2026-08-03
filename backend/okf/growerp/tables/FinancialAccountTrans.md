---
type: Moqui Entity
title: FinancialAccountTrans
description: "Financial Account Trans"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccountTrans
tags: [mantle, account, financial]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FinancialAccountTrans

Financial Account Trans

Full entity name: `mantle.account.financial.FinancialAccountTrans`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `finAccountTransId` | id | Y |  |
| `finAccountTransTypeEnumId` | id |  |  |
| `finAccountId` | id |  |  |
| `finAccountAuthId` | id |  | Only set for withdrawals based on an auth. |
| `fromPartyId` | id |  |  |
| `toPartyId` | id |  |  |
| `glReconciliationId` | id |  |  |
| `reasonEnumId` | id |  | Used to determine the balancing GlAccount to the one based on FinancialAccount.finAccountTypeId. |
| `transactionDate` | date-time |  |  |
| `entryDate` | date-time |  |  |
| `amount` | currency-amount |  |  |
| `postBalance` | currency-amount |  |  |
| `paymentId` | id |  |  |
| `invoiceId` | id |  |  |
| `invoiceItemSeqId` | id |  | To be used along with invoiceId to point to an InvoiceItem that this transaction is based on, such as a full or partial credit against a charge. |
| `orderId` | id |  |  |
| `orderItemSeqId` | id |  | To be used along with orderId to point to an OrderItem that represents the purchase of a product to add money to the account. |
| `otherFinAccountTransId` | id |  | For FinancialAccount transfer transaction pairs |
| `performedByUserId` | id |  |  |
| `acctgTransResultEnumId` | id |  |  |
| `reversedByTransId` | id |  |  |
| `reverseOfTransId` | id |  |  |
| `comments` | text-medium |  |  |
| `externalId` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `finAccountTransTypeEnumId`
- one [FinancialAccount](FinancialAccount.md) via `finAccountId`
- one [FinancialAccountAuth](FinancialAccountAuth.md) via `finAccountAuthId`
- one [From Party](Party.md) via `fromPartyId`
- one [To Party](Party.md) via `toPartyId`
- one [GlReconciliation](GlReconciliation.md) via `glReconciliationId`
- one `moqui.basic.Enumeration` via `reasonEnumId`
- one [Payment](Payment.md) via `paymentId`
- one [Invoice](Invoice.md) via `invoiceId`
- one-nofk [OrderHeader](OrderHeader.md) via `orderId`
- one [OrderItem](OrderItem.md) via `orderId`, `orderItemSeqId`
- one `moqui.security.UserAccount` via `performedByUserId`
- one `moqui.basic.Enumeration` via `acctgTransResultEnumId`
- one [ReversedBy FinancialAccountTrans](FinancialAccountTrans.md) via `reversedByTransId`
- one [ReverseOf FinancialAccountTrans](FinancialAccountTrans.md) via `reverseOfTransId`
- many [InvoiceItem](InvoiceItem.md) via `finAccountTransId`
- many [AcctgTrans](AcctgTrans.md) via `finAccountTransId`
- many [ReturnItem](ReturnItem.md) via `finAccountTransId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.financial.FinancialAccountTrans

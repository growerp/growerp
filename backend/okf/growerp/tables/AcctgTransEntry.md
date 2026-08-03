---
type: Moqui Entity
title: AcctgTransEntry
description: "Acctg Trans Entry"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.transaction.AcctgTransEntry
tags: [mantle, ledger, transaction]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AcctgTransEntry

Acctg Trans Entry

Full entity name: `mantle.ledger.transaction.AcctgTransEntry`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `acctgTransId` | id | Y |  |
| `acctgTransEntrySeqId` | id | Y |  |
| `debitCreditFlag` | text-indicator |  | If D is a debit, if C is a credit. |
| `amount` | currency-amount |  |  |
| `localCurrencyAmount` | currency-amount |  |  |
| `originalCurrencyAmount` | currency-amount |  |  |
| `description` | text-medium |  |  |
| `voucherRef` | text-short |  |  |
| `glAccountTypeEnumId` | id |  |  |
| `glAccountId` | id |  |  |
| `dueDate` | date |  |  |
| `reconcileStatusId` | id |  |  |
| `settlementTermId` | id |  |  |
| `isSummary` | text-indicator |  | Set to Y if this is a summary entry from a sub-ledger. |
| `productId` | id |  |  |
| `externalProductId` | id |  |  |
| `assetId` | id |  |  |
| `invoiceItemSeqId` | id |  |  |
| `pseudoProductId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AcctgTrans](AcctgTrans.md) via `acctgTransId`
- one `moqui.basic.Enumeration` via `glAccountTypeEnumId`
- one [GlAccount](GlAccount.md) via `glAccountId`
- one `moqui.basic.StatusItem` via `reconcileStatusId`
- one [SettlementTerm](SettlementTerm.md) via `settlementTermId`
- one [Product](Product.md) via `productId`
- one [Asset](Asset.md) via `assetId`
- many [PaymentMethodTrans](PaymentMethodTrans.md) via `acctgTransId`, `acctgTransEntrySeqId`
- many [GlReconciliationEntry](GlReconciliationEntry.md) via `acctgTransId`, `acctgTransEntrySeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.transaction.AcctgTransEntry

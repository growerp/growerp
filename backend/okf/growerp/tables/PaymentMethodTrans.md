---
type: Moqui Entity
title: PaymentMethodTrans
description: "Transactions of the PaymentMethod, such as imported from an OFX file (see www.ofx.net); can be imported from any source and reconciled in a more consistent way from here"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethodTrans
tags: [mantle, account, method]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentMethodTrans

Transactions of the PaymentMethod, such as imported from an OFX file (see www.ofx.net); can be imported from any source and reconciled in a more consistent way from here

Full entity name: `mantle.account.method.PaymentMethodTrans`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentMethodId` | id | Y |  |
| `fitId` | text-short | Y | Financial Institution Transaction ID (OFX STMTTRN.FITID) |
| `transType` | text-short |  | Transaction type (OFX STMTTRN.TRNTYPE), either literal value or enumId with enumTypeId PaymentMethodTransType |
| `transCode` | text-short |  | The original transaction type code, will be same as transType unless enumId used for transType |
| `postedDate` | date-time |  | Date posted (OFX STMTTRN.DTPOSTED) |
| `transAmount` | currency-amount |  | Transaction amount (OFX STMTTRN.TRNAMT) |
| `transName` | text-short |  | Transaction name (OFX STMTTRN.NAME or PAYEE; as per spec only one may be used) |
| `transMemo` | text-medium |  | Transaction memo (OFX STMTTRN.MEMO) |
| `checkNumber` | text-short |  | Check number, rarely included but very useful for reconciliation (OFX STMTTRN.CHECKNUM) |
| `refNumber` | text-short |  | Reference number (OFX STMTTRN.REFNUM) |
| `paymentId` | id |  |  |
| `acctgTransId` | id |  |  |
| `acctgTransEntrySeqId` | id |  |  |
| `noReconcile` | text-indicator |  | If Y this transaction is not to be reconciled, represents multiple payments or otherwise |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PaymentMethod](PaymentMethod.md) via `paymentMethodId`
- one-nofk `moqui.basic.Enumeration` via `transType`
- one [Payment](Payment.md) via `paymentId`
- one [AcctgTransEntry](AcctgTransEntry.md) via `acctgTransId`, `acctgTransEntrySeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.method.PaymentMethodTrans

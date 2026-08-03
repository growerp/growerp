---
type: Moqui Entity
title: AcctgTrans
description: "Acctg Trans"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.transaction.AcctgTrans
tags: [mantle, ledger, transaction]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AcctgTrans

Acctg Trans

Full entity name: `mantle.ledger.transaction.AcctgTrans`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `acctgTransId` | id | Y |  |
| `acctgTransTypeEnumId` | id |  |  |
| `organizationPartyId` | id |  |  |
| `description` | text-medium |  |  |
| `transactionDate` | date-time |  |  |
| `isPosted` | text-indicator |  |  |
| `postedDate` | date-time |  |  |
| `scheduledPostingDate` | date-time |  |  |
| `glJournalId` | id |  |  |
| `glFiscalTypeEnumId` | id |  |  |
| `voucherRef` | text-short |  |  |
| `voucherDate` | date-time |  |  |
| `groupStatusId` | id |  |  |
| `amountUomId` | id |  | The unit of account (base) currency, must match PartyAcctgPreference.baseCurrencyUomId |
| `localCurrencyUomId` | id |  | The local currency for the Organization, must match PartyAcctgPreference.localCurrencyUomId |
| `originalCurrencyUomId` | id |  | The original currency for the invoice, payment, etc - the currency used to interact with the external Party |
| `assetId` | id |  |  |
| `assetIssuanceId` | id |  |  |
| `assetReceiptId` | id |  |  |
| `physicalInventoryId` | id |  |  |
| `otherPartyId` | id |  |  |
| `invoiceId` | id |  |  |
| `paymentId` | id |  |  |
| `paymentApplicationId` | id |  |  |
| `toInvoiceId` | id |  |  |
| `toPaymentId` | id |  |  |
| `finAccountTransId` | id |  |  |
| `shipmentId` | id |  |  |
| `workEffortId` | id |  |  |
| `theirAcctgTransId` | text-short |  |  |
| `reversedByAcctgTransId` | id |  |  |
| `reverseOfAcctgTransId` | id |  |  |
| `pseudoId` | id |  |  |
| `pseudoFinDocId` | id |  |  |
| `docType` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `acctgTransTypeEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlJournal](GlJournal.md) via `glJournalId`
- one `moqui.basic.Enumeration` via `glFiscalTypeEnumId`
- one `moqui.basic.StatusItem` via `groupStatusId`
- one `moqui.basic.Uom` via `amountUomId`
- one `moqui.basic.Uom` via `localCurrencyUomId`
- one `moqui.basic.Uom` via `originalCurrencyUomId`
- one [Asset](Asset.md) via `assetId`
- one [AssetIssuance](AssetIssuance.md) via `assetIssuanceId`
- one [AssetReceipt](AssetReceipt.md) via `assetReceiptId`
- one [PhysicalInventory](PhysicalInventory.md) via `physicalInventoryId`
- one [Other Party](Party.md) via `otherPartyId`
- one [Invoice](Invoice.md) via `invoiceId`
- one [Payment](Payment.md) via `paymentId`
- one [PaymentApplication](PaymentApplication.md) via `paymentApplicationId`
- one [To Invoice](Invoice.md) via `toInvoiceId`
- one [To Payment](Payment.md) via `toPaymentId`
- one [FinancialAccountTrans](FinancialAccountTrans.md) via `finAccountTransId`
- one [Shipment](Shipment.md) via `shipmentId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [ReversedBy AcctgTrans](AcctgTrans.md) via `reversedByAcctgTransId`
- one [ReverseOf AcctgTrans](AcctgTrans.md) via `reverseOfAcctgTransId`
- many [AcctgTransEntry](AcctgTransEntry.md) via `acctgTransId`
- many [GlReconciliationEntry](GlReconciliationEntry.md) via `acctgTransId`
- many [AssetDepreciation](AssetDepreciation.md) via `acctgTransId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.transaction.AcctgTrans

---
type: Moqui Entity
title: InvoiceItem
description: "Invoice Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceItem
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceItem

Invoice Item

Full entity name: `mantle.account.invoice.InvoiceItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceId` | id | Y |  |
| `invoiceItemSeqId` | id | Y |  |
| `parentItemSeqId` | id |  |  |
| `itemTypeEnumId` | id |  |  |
| `overrideGlAccountId` | id |  | The override or actual glAccountId used for the AcctgTransEntry based on the InvoiceItem. If empty the glAccountId will be determined based on configuration or custom code. |
| `assetId` | id |  | For sale of a particular asset, required for fixed assets |
| `productId` | id |  |  |
| `otherPartyProductId` | text-short |  |  |
| `parentInvoiceId` | id |  |  |
| `parentInvoiceItemSeqId` | id |  |  |
| `taxableFlag` | text-indicator |  |  |
| `quantity` | number-decimal |  |  |
| `quantityUomId` | id |  |  |
| `amount` | currency-precise |  |  |
| `description` | text-medium |  |  |
| `itemDate` | date-time |  |  |
| `isAdjustment` | text-indicator |  |  |
| `salesOpportunityId` | id |  |  |
| `taxAuthorityId` | id |  |  |
| `payrollAdjustmentId` | id |  |  |
| `finAccountId` | id |  |  |
| `finAccountTransId` | id |  |  |
| `billThruVendorName` | text-medium |  | For tracking purposes when there is no associated bill through invoice with InvoiceItemAssoc records |
| `billThruVendorRef` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Invoice](Invoice.md) via `invoiceId`
- one-nofk [Parent InvoiceItem](InvoiceItem.md) via `invoiceId`, `parentItemSeqId`
- many [Child InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one `moqui.basic.Enumeration` via `itemTypeEnumId`
- one [Asset](Asset.md) via `assetId`
- one [Product](Product.md) via `productId`
- one [OtherParent InvoiceItem](InvoiceItem.md) via `parentInvoiceId`, `parentInvoiceItemSeqId`
- one [Override GlAccount](GlAccount.md) via `overrideGlAccountId`
- one `moqui.basic.Uom` via `quantityUomId`
- one [SalesOpportunity](SalesOpportunity.md) via `salesOpportunityId`
- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one [PayrollAdjustment](PayrollAdjustment.md) via `payrollAdjustmentId`
- one [FinancialAccount](FinancialAccount.md) via `finAccountId`
- one [FinancialAccountTrans](FinancialAccountTrans.md) via `finAccountTransId`
- many [InvoiceItemDetail](InvoiceItemDetail.md) via `invoiceId`, `invoiceItemSeqId`
- many [OrderItemBilling](OrderItemBilling.md) via `invoiceId`, `invoiceItemSeqId`
- many [ShipmentItemSource](ShipmentItemSource.md) via `invoiceId`, `invoiceItemSeqId`
- many [AssetIssuance](AssetIssuance.md) via `invoiceId`, `invoiceItemSeqId`
- many [AssetReceipt](AssetReceipt.md) via `invoiceId`, `invoiceItemSeqId`
- many [InvoiceItemAssoc](InvoiceItemAssoc.md) via `invoiceId`, `invoiceItemSeqId`
- many [To InvoiceItemAssoc](InvoiceItemAssoc.md) via `invoiceId`, `invoiceItemSeqId`
- many [InvoiceTerm](InvoiceTerm.md) via `invoiceId`, `invoiceItemSeqId`
- many [PaymentApplication](PaymentApplication.md) via `invoiceId`, `invoiceItemSeqId`
- many [ReturnItemBilling](ReturnItemBilling.md) via `invoiceId`, `invoiceItemSeqId`
- many [WorkEffortBilling](WorkEffortBilling.md) via `invoiceId`, `invoiceItemSeqId`
- many [TimeEntry](TimeEntry.md) via `invoiceId`, `invoiceItemSeqId`
- many [Vendor TimeEntry](TimeEntry.md) via `invoiceId`, `invoiceItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceItem

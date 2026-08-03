---
type: Moqui Entity
title: Invoice
description: "Invoice"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.Invoice
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Invoice

Invoice

Full entity name: `mantle.account.invoice.Invoice`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceId` | id | Y |  |
| `invoiceTypeEnumId` | id |  |  |
| `fromPartyId` | id |  |  |
| `toPartyId` | id |  |  |
| `statusId` | id |  |  |
| `billingAccountId` | id |  |  |
| `invoiceDate` | date-time |  |  |
| `dueDate` | date-time |  |  |
| `settlementTermId` | id |  |  |
| `paidDate` | date-time |  |  |
| `invoiceMessage` | text-long |  |  |
| `referenceNumber` | text-medium |  | Vendor or other invoice number. |
| `otherPartyOrderId` | text-short |  |  |
| `description` | text-medium |  |  |
| `currencyUomId` | id |  | The original (external) currency |
| `overrideOrgPartyId` | id |  | Used to specify the organization override rather than using the fromPartyId and/or toPartyId (depending on which is an internal org). |
| `productStoreId` | id |  | For sales invoices processed through a ProductStore, copied from order if applicable |
| `partyRelationshipId` | id |  | For Payroll invoices, points to Employment record |
| `timePeriodId` | id |  | For Payroll invoices, points to Payroll TimePeriod |
| `acctgTransResultEnumId` | id |  |  |
| `systemMessageRemoteId` | id |  |  |
| `externalId` | text-short |  | ID for the invoice in the direct upstream system it came from if it came from an external system |
| `originId` | text-short |  | ID for the invoice in the original system it came from if not the direct upstream system |
| `invoiceTotal` | currency-amount |  |  |
| `appliedPaymentsTotal` | currency-amount |  | Total of all PaymentApplication records by invoiceId or toInvoiceId, ie includes payments and invoices applied to/from this invoice. |
| `unpaidTotal` | currency-amount |  |  |
| `pseudoId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `invoiceTypeEnumId`
- one [From Party](Party.md) via `fromPartyId`
- one-nofk [From Organization](Organization.md) via `fromPartyId`
- one-nofk [From Person](Person.md) via `fromPartyId`
- many [From PartyRole](PartyRole.md) via `fromPartyId`
- one [To Party](Party.md) via `toPartyId`
- one-nofk [To Organization](Organization.md) via `toPartyId`
- one-nofk [To Person](Person.md) via `toPartyId`
- many [To PartyRole](PartyRole.md) via `toPartyId`
- many [To PartyClassificationAppl](PartyClassificationAppl.md) via `toPartyId`
- one `moqui.basic.StatusItem` via `statusId`
- one [BillingAccount](BillingAccount.md) via `billingAccountId`
- one [SettlementTerm](SettlementTerm.md) via `settlementTermId`
- one `moqui.basic.Uom` via `currencyUomId`
- one [OverrideOrg Party](Party.md) via `overrideOrgPartyId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- one [Employment](Employment.md) via `partyRelationshipId`
- one [TimePeriod](TimePeriod.md) via `timePeriodId`
- one `moqui.basic.Enumeration` via `acctgTransResultEnumId`
- one `moqui.service.message.SystemMessageRemote` via `systemMessageRemoteId`
- many [InvoiceItem](InvoiceItem.md) via `invoiceId`
- many [PaymentApplication](PaymentApplication.md) via `invoiceId`
- many [To PaymentApplication](PaymentApplication.md) via `invoiceId`
- many [AcctgTrans](AcctgTrans.md) via `invoiceId`
- many [FinancialAccountTrans](FinancialAccountTrans.md) via `invoiceId`
- many [InvoiceContactMech](InvoiceContactMech.md) via `invoiceId`
- many [InvoiceContent](InvoiceContent.md) via `invoiceId`
- many [InvoiceEmailMessage](InvoiceEmailMessage.md) via `invoiceId`
- many [InvoiceItemDetail](InvoiceItemDetail.md) via `invoiceId`
- many [InvoiceParty](InvoiceParty.md) via `invoiceId`
- many [InvoiceSystemMessage](InvoiceSystemMessage.md) via `invoiceId`
- many [InvoiceTerm](InvoiceTerm.md) via `invoiceId`
- many [For Payment](Payment.md) via `invoiceId`
- many [EmploymentPayHistory](EmploymentPayHistory.md) via `invoiceId`
- many [To AcctgTrans](AcctgTrans.md) via `invoiceId`
- many [AssetIssuance](AssetIssuance.md) via `invoiceId`
- many [WorkEffortInvoice](WorkEffortInvoice.md) via `invoiceId`
- many `moqui.service.message.SystemMessage` via `invoiceId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.Invoice

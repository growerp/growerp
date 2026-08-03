---
type: Moqui Entity
title: PaymentApplication
description: "Payment application to settle payments and invoices. Can be used for multiple scenarios using different fields: 1. Apply a Payment (paymentId) to an Invoice (invoiceId) 2. Apply a Payment (paymentId) such as a refund to another Payment (toPaymentId) such as an invoice payment 3. Apply an Invoice (invoiceId) such as a Credit Memo payable to another Invoice (toInvoiceId) such as a Sales/Purchase receivable In all cases the two opposing records should have reverse from/to party IDs. To constrain to these three scenarios if toPaymentId is set paymentId should always be set, and if toInvoiceId is set invoiceId should always be set."
resource: http://127.0.0.1:8080/rest/e1/mantle.account.payment.PaymentApplication
tags: [mantle, account, payment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentApplication

Payment application to settle payments and invoices. Can be used for multiple scenarios using different fields: 1. Apply a Payment (paymentId) to an Invoice (invoiceId) 2. Apply a Payment (paymentId) such as a refund to another Payment (toPaymentId) such as an invoice payment 3. Apply an Invoice (invoiceId) such as a Credit Memo payable to another Invoice (toInvoiceId) such as a Sales/Purchase receivable In all cases the two opposing records should have reverse from/to party IDs. To constrain to these three scenarios if toPaymentId is set paymentId should always be set, and if toInvoiceId is set invoiceId should always be set.

Full entity name: `mantle.account.payment.PaymentApplication`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentApplicationId` | id | Y |  |
| `paymentId` | id |  |  |
| `invoiceId` | id |  |  |
| `billingAccountId` | id |  |  |
| `overrideGlAccountId` | id |  | If specified payment is applied directly against this GL account instead of the mapped AR/AP account |
| `toPaymentId` | id |  | Use to apply a Payment to another Payment like a payment that is a return of a mistaken or over-payment |
| `toInvoiceId` | id |  | Use to apply an Invoice to another Invoice like a Credit Memo payable to a Sales/Purchase receivable |
| `taxAuthGeoId` | id |  |  |
| `amountApplied` | currency-amount |  |  |
| `amountOriginallyApplied` | currency-amount |  |  |
| `appliedDate` | date-time |  |  |
| `acctgTransResultEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Payment](Payment.md) via `paymentId`
- one [Invoice](Invoice.md) via `invoiceId`
- one-nofk [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [BillingAccount](BillingAccount.md) via `billingAccountId`
- one [To Payment](Payment.md) via `toPaymentId`
- one [To Invoice](Invoice.md) via `toInvoiceId`
- one `moqui.basic.Geo` via `taxAuthGeoId`
- one [Override GlAccount](GlAccount.md) via `overrideGlAccountId`
- one `moqui.basic.Enumeration` via `acctgTransResultEnumId`
- many [AcctgTrans](AcctgTrans.md) via `paymentApplicationId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.payment.PaymentApplication

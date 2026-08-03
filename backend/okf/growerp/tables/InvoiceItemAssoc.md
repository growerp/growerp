---
type: Moqui Entity
title: InvoiceItemAssoc
description: "Invoice Item Assoc"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceItemAssoc
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceItemAssoc

Invoice Item Assoc

Full entity name: `mantle.account.invoice.InvoiceItemAssoc`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceItemAssocId` | id | Y |  |
| `invoiceId` | id |  |  |
| `invoiceItemSeqId` | id |  |  |
| `toInvoiceId` | id |  |  |
| `toInvoiceItemSeqId` | id |  |  |
| `invoiceItemAssocTypeEnumId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `fromPartyId` | id |  |  |
| `toPartyId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `amount` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `invoiceItemAssocTypeEnumId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [To InvoiceItem](InvoiceItem.md) via `toInvoiceId`, `toInvoiceItemSeqId`
- one [From Party](Party.md) via `fromPartyId`
- one [To Party](Party.md) via `toPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceItemAssoc

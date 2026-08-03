---
type: Moqui Entity
title: InvoiceTerm
description: "Invoice Term"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceTerm
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceTerm

Invoice Term

Full entity name: `mantle.account.invoice.InvoiceTerm`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceId` | id | Y |  |
| `invoiceItemSeqId` | id | Y |  |
| `settlementTermId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Invoice](Invoice.md) via `invoiceId`
- one-nofk [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [SettlementTerm](SettlementTerm.md) via `settlementTermId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceTerm

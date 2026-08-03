---
type: Moqui Entity
title: InvoiceEmailMessage
description: "Invoice Email Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceEmailMessage
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceEmailMessage

Invoice Email Message

Full entity name: `mantle.account.invoice.InvoiceEmailMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceId` | id | Y |  |
| `emailMessageId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Invoice](Invoice.md) via `invoiceId`
- one `moqui.basic.email.EmailMessage` via `emailMessageId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceEmailMessage

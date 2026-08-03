---
type: Moqui Entity
title: InvoiceSystemMessage
description: "Invoice System Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceSystemMessage
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceSystemMessage

Invoice System Message

Full entity name: `mantle.account.invoice.InvoiceSystemMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceId` | id | Y |  |
| `systemMessageId` | id | Y |  |
| `externalId` | text-short |  |  |
| `originId` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Invoice](Invoice.md) via `invoiceId`
- one `moqui.service.message.SystemMessage` via `systemMessageId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceSystemMessage

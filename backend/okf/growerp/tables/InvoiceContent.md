---
type: Moqui Entity
title: InvoiceContent
description: "Invoice Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceContent
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceContent

Invoice Content

Full entity name: `mantle.account.invoice.InvoiceContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceContentId` | id | Y |  |
| `invoiceId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `contentTypeEnumId` | id |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Invoice](Invoice.md) via `invoiceId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceContent

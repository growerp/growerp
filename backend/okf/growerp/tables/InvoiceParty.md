---
type: Moqui Entity
title: InvoiceParty
description: "Invoice Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceParty
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceParty

Invoice Party

Full entity name: `mantle.account.invoice.InvoiceParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Invoice](Invoice.md) via `invoiceId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceParty

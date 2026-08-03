---
type: Moqui Entity
title: InvoiceContactMech
description: "Invoice Contact Mech"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceContactMech
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceContactMech

Invoice Contact Mech

Full entity name: `mantle.account.invoice.InvoiceContactMech`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceId` | id | Y |  |
| `contactMechPurposeId` | id | Y |  |
| `contactMechId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Invoice](Invoice.md) via `invoiceId`
- one [ContactMechPurpose](ContactMechPurpose.md) via `contactMechPurposeId`
- one [ContactMech](ContactMech.md) via `contactMechId`
- one-nofk [PostalAddress](PostalAddress.md) via `contactMechId`
- one-nofk [TelecomNumber](TelecomNumber.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceContactMech

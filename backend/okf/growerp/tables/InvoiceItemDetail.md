---
type: Moqui Entity
title: InvoiceItemDetail
description: "Invoice Item Detail"
resource: http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceItemDetail
tags: [mantle, account, invoice]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceItemDetail

Invoice Item Detail

Full entity name: `mantle.account.invoice.InvoiceItemDetail`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceItemDetailId` | id | Y |  |
| `invoiceId` | id |  |  |
| `invoiceItemSeqId` | id |  |  |
| `facilityId` | id |  |  |
| `assetId` | id |  |  |
| `partyId` | id |  |  |
| `workEffortId` | id |  |  |
| `quantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one-nofk [Invoice](Invoice.md) via `invoiceId`
- one [InvoiceItem](InvoiceItem.md) via `invoiceId`, `invoiceItemSeqId`
- one [Facility](Facility.md) via `facilityId`
- one [Asset](Asset.md) via `assetId`
- one [Party](Party.md) via `partyId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.account.invoice.InvoiceItemDetail

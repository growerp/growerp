---
type: Moqui Entity
title: InvoiceTypeTransType
description: "Invoice Type Trans Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.InvoiceTypeTransType
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# InvoiceTypeTransType

Invoice Type Trans Type

Full entity name: `mantle.ledger.config.InvoiceTypeTransType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `invoiceTypeEnumId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `isPayable` | text-indicator | Y | If Y is Payable, N is Receivable. |
| `acctgTransTypeEnumId` | id |  |  |
| `glAccountId` | id |  | If not specified uses the GlAccountTypeDefault setting for GatAccountsReceivable or GatAccountsPayable |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `invoiceTypeEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one `moqui.basic.Enumeration` via `acctgTransTypeEnumId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.InvoiceTypeTransType

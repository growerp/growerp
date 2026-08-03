---
type: Moqui Entity
title: PaymentTypeGlAccount
description: "Payment Type Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.PaymentTypeGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentTypeGlAccount

Payment Type Gl Account

Full entity name: `mantle.ledger.config.PaymentTypeGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentTypeEnumId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `isPayable` | text-indicator | Y | If Y is Payable, N is Receivable. |
| `isApplied` | text-indicator | Y | If Y is for Applied Payment, N for Unapplied Payment, E for either. |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `paymentTypeEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.PaymentTypeGlAccount

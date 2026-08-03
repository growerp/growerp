---
type: Moqui Entity
title: PaymentInstrumentGlAccount
description: "Payment Instrument Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.PaymentInstrumentGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PaymentInstrumentGlAccount

Payment Instrument Gl Account

Full entity name: `mantle.ledger.config.PaymentInstrumentGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `paymentInstrumentEnumId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `isPayable` | text-indicator | Y | If Y is Payable, N is Receivable, E for either. |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `paymentInstrumentEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.PaymentInstrumentGlAccount

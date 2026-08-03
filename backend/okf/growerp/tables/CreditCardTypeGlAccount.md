---
type: Moqui Entity
title: CreditCardTypeGlAccount
description: "Credit Card Type Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.CreditCardTypeGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CreditCardTypeGlAccount

Credit Card Type Gl Account

Full entity name: `mantle.ledger.config.CreditCardTypeGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `creditCardTypeEnumId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `creditCardTypeEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.CreditCardTypeGlAccount

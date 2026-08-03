---
type: Moqui Entity
title: TaxAuthorityGlAccount
description: "Tax Authority Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.TaxAuthorityGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# TaxAuthorityGlAccount

Tax Authority Gl Account

Full entity name: `mantle.ledger.config.TaxAuthorityGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `taxAuthorityId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [TaxAuthority](TaxAuthority.md) via `taxAuthorityId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.TaxAuthorityGlAccount

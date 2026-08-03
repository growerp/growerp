---
type: Moqui Entity
title: GlAccountOrganization
description: "Gl Account Organization"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountOrganization
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccountOrganization

Gl Account Organization

Full entity name: `mantle.ledger.account.GlAccountOrganization`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `postedBalance` | currency-amount |  |  |
| `balanceLastUpdated` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [GlAccount](GlAccount.md) via `glAccountId`
- one [Organization Party](Party.md) via `organizationPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountOrganization

---
type: Moqui Entity
title: FinancialAccountReasonGlAccount
description: "Financial Account Reason Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.FinancialAccountReasonGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FinancialAccountReasonGlAccount

Financial Account Reason Gl Account

Full entity name: `mantle.ledger.config.FinancialAccountReasonGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `reasonEnumId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `reasonEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.FinancialAccountReasonGlAccount

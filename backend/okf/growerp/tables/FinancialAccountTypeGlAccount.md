---
type: Moqui Entity
title: FinancialAccountTypeGlAccount
description: "Financial Account Type Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.FinancialAccountTypeGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# FinancialAccountTypeGlAccount

Financial Account Type Gl Account

Full entity name: `mantle.ledger.config.FinancialAccountTypeGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `finAccountTypeId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [FinancialAccountType](FinancialAccountType.md) via `finAccountTypeId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.FinancialAccountTypeGlAccount

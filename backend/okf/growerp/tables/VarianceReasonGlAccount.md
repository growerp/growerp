---
type: Moqui Entity
title: VarianceReasonGlAccount
description: "Variance Reason Gl Account"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.VarianceReasonGlAccount
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# VarianceReasonGlAccount

Variance Reason Gl Account

Full entity name: `mantle.ledger.config.VarianceReasonGlAccount`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `varianceReasonEnumId` | id | Y |  |
| `organizationPartyId` | id | Y |  |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `varianceReasonEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.VarianceReasonGlAccount

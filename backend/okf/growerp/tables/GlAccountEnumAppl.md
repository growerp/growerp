---
type: Moqui Entity
title: GlAccountEnumAppl
description: "Used to specify relevant GL Accounts for an Enumeration (expense, revenue, etc); not related to posting conf"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountEnumAppl
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccountEnumAppl

Used to specify relevant GL Accounts for an Enumeration (expense, revenue, etc); not related to posting conf

Full entity name: `mantle.ledger.account.GlAccountEnumAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountId` | id | Y |  |
| `enumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [GlAccount](GlAccount.md) via `glAccountId`
- one `moqui.basic.Enumeration` via `enumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountEnumAppl

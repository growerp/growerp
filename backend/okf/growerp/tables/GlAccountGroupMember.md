---
type: Moqui Entity
title: GlAccountGroupMember
description: "Gl Account Group Member"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountGroupMember
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccountGroupMember

Gl Account Group Member

Full entity name: `mantle.ledger.account.GlAccountGroupMember`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountId` | id | Y |  |
| `groupTypeEnumId` | id | Y |  |
| `glAccountGroupId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [GlAccount](GlAccount.md) via `glAccountId`
- one `moqui.basic.Enumeration` via `groupTypeEnumId`
- one [GlAccountGroup](GlAccountGroup.md) via `glAccountGroupId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountGroupMember

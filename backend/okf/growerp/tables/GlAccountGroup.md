---
type: Moqui Entity
title: GlAccountGroup
description: "A grouping of GlAccount records for purposes of reporting and populating forms such as tax forms. It is structured so that each GlAccount can be a member of at most one group of each type."
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountGroup
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccountGroup

A grouping of GlAccount records for purposes of reporting and populating forms such as tax forms. It is structured so that each GlAccount can be a member of at most one group of each type.

Full entity name: `mantle.ledger.account.GlAccountGroup`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountGroupId` | id | Y |  |
| `groupTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `groupTypeEnumId`
- many [GlAccountGroupMember](GlAccountGroupMember.md) via `glAccountGroupId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountGroup

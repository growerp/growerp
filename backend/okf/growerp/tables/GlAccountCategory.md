---
type: Moqui Entity
title: GlAccountCategory
description: "Gl Account Category"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountCategory
tags: [mantle, ledger, account]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccountCategory

Gl Account Category

Full entity name: `mantle.ledger.account.GlAccountCategory`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glAccountCategoryId` | id | Y |  |
| `categoryTypeEnumId` | id |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `categoryTypeEnumId`
- many [GlAccountCategoryMember](GlAccountCategoryMember.md) via `glAccountCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.account.GlAccountCategory

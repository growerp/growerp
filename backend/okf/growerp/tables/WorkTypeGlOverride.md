---
type: Moqui Entity
title: WorkTypeGlOverride
description: "Work Type Gl Override"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.WorkTypeGlOverride
tags: [mantle, humanres, employment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkTypeGlOverride

Work Type Gl Override

Full entity name: `mantle.humanres.employment.WorkTypeGlOverride`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `organizationPartyId` | id | Y |  |
| `workTypeEnumId` | id | Y |  |
| `itemTypeEnumId` | id | Y |  |
| `overrideGlAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Organization Party](Party.md) via `organizationPartyId`
- one `moqui.basic.Enumeration` via `workTypeEnumId`
- one `moqui.basic.Enumeration` via `itemTypeEnumId`
- one [Override GlAccount](GlAccount.md) via `overrideGlAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.employment.WorkTypeGlOverride

---
type: Moqui Entity
title: EmplPositionClassWorkType
description: "An alternative to EmplPosition and Employment to represent an employee in a position class for billing purposes, etc. Can be used in addition to EmplPosition or instead of."
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClassWorkType
tags: [mantle, humanres, position]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplPositionClassWorkType

An alternative to EmplPosition and Employment to represent an employee in a position class for billing purposes, etc. Can be used in addition to EmplPosition or instead of.

Full entity name: `mantle.humanres.position.EmplPositionClassWorkType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionClassId` | id | Y |  |
| `workTypeEnumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one `moqui.basic.Enumeration` via `workTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClassWorkType

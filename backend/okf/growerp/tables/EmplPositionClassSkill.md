---
type: Moqui Entity
title: EmplPositionClassSkill
description: "Empl Position Class Skill"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClassSkill
tags: [mantle, humanres, position]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplPositionClassSkill

Empl Position Class Skill

Full entity name: `mantle.humanres.position.EmplPositionClassSkill`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionClassId` | id | Y |  |
| `skillTypeEnumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one `moqui.basic.Enumeration` via `skillTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClassSkill

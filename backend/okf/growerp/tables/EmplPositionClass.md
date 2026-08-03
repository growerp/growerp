---
type: Moqui Entity
title: EmplPositionClass
description: "Empl Position Class"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClass
tags: [mantle, humanres, position]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplPositionClass

Empl Position Class

Full entity name: `mantle.humanres.position.EmplPositionClass`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionClassId` | id | Y |  |
| `title` | text-medium |  |  |
| `description` | text-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- many [EmplClassResponsibility](EmplClassResponsibility.md) via `emplPositionClassId`
- many [EmplPosition](EmplPosition.md) via `emplPositionClassId`
- many [EmplPositionClassDimension](EmplPositionClassDimension.md) via `emplPositionClassId`
- many [EmplPositionClassParty](EmplPositionClassParty.md) via `emplPositionClassId`
- many [EmplPositionClassSkill](EmplPositionClassSkill.md) via `emplPositionClassId`
- many [EmplPositionClassWorkType](EmplPositionClassWorkType.md) via `emplPositionClassId`
- many [RateAmount](RateAmount.md) via `emplPositionClassId`
- many [EmplPositionClassPtyClsTp](EmplPositionClassPtyClsTp.md) via `emplPositionClassId`
- many [WorkEffortParty](WorkEffortParty.md) via `emplPositionClassId`
- many [TimeEntry](TimeEntry.md) via `emplPositionClassId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClass

---
type: Moqui Entity
title: WorkEffortSkillStandard
description: "Work Effort Skill Standard"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortSkillStandard
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortSkillStandard

Work Effort Skill Standard

Full entity name: `mantle.work.effort.WorkEffortSkillStandard`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `skillTypeEnumId` | id | Y |  |
| `estimatedNumPeople` | number-decimal |  |  |
| `estimatedDuration` | number-decimal |  |  |
| `estimatedCost` | currency-amount |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one `moqui.basic.Enumeration` via `skillTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortSkillStandard

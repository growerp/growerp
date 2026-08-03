---
type: Moqui Entity
title: WorkEffortCategoryAppl
description: "Work Effort Category Appl"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortCategoryAppl
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortCategoryAppl

Work Effort Category Appl

Full entity name: `mantle.work.effort.WorkEffortCategoryAppl`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `workEffortCategoryId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- many [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortCategoryAppl

---
type: Moqui Entity
title: WorkEffortNote
description: "Work Effort Note"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortNote
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortNote

Work Effort Note

Full entity name: `mantle.work.effort.WorkEffortNote`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `noteDate` | date-time | Y |  |
| `noteText` | text-very-long |  |  |
| `internalNote` | text-indicator |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortNote

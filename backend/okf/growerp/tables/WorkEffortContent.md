---
type: Moqui Entity
title: WorkEffortContent
description: "Work Effort Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortContent
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortContent

Work Effort Content

Full entity name: `mantle.work.effort.WorkEffortContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortContentId` | id | Y |  |
| `workEffortId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `contentTypeEnumId` | id |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortContent

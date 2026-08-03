---
type: Moqui Entity
title: WorkEffortCategory
description: "Categories for WorkEffort, especially events like iCal/VCALENDAR categories"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortCategory
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortCategory

Categories for WorkEffort, especially events like iCal/VCALENDAR categories

Full entity name: `mantle.work.effort.WorkEffortCategory`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortCategoryId` | id | Y |  |
| `description` | text-medium |  |  |
| `ownerPartyId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortCategory

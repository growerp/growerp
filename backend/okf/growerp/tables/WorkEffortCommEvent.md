---
type: Moqui Entity
title: WorkEffortCommEvent
description: "Work Effort Comm Event"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortCommEvent
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WorkEffortCommEvent

Work Effort Comm Event

Full entity name: `mantle.work.effort.WorkEffortCommEvent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `workEffortId` | id | Y |  |
| `communicationEventId` | id | Y |  |
| `description` | text-medium |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WorkEffort](WorkEffort.md) via `workEffortId`
- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WorkEffortCommEvent

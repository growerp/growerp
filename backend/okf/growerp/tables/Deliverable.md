---
type: Moqui Entity
title: Deliverable
description: "Deliverable"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.Deliverable
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Deliverable

Deliverable

Full entity name: `mantle.work.effort.Deliverable`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `deliverableId` | id | Y |  |
| `deliverableTypeEnumId` | id |  |  |
| `deliverableName` | text-medium |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `deliverableTypeEnumId`
- many [Requirement](Requirement.md) via `deliverableId`
- many [WorkEffortDeliverableProd](WorkEffortDeliverableProd.md) via `deliverableId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.Deliverable

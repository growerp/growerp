---
type: Moqui Entity
title: RoutingTask
description: "Routing Task"
resource: http://127.0.0.1:8080/rest/e1/growerp.manufacturing.RoutingTask
tags: [growerp, manufacturing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RoutingTask

Routing Task

Full entity name: `growerp.manufacturing.RoutingTask`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `routingTaskId` | id | Y |  |
| `routingId` | id |  |  |
| `taskName` | text-short |  |  |
| `sequenceNum` | number-integer |  |  |
| `estimatedWorkTime` | number-decimal |  |  |
| `workCenterName` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Routing](Routing.md) via `routingId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.manufacturing.RoutingTask

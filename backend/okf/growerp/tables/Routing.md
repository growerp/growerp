---
type: Moqui Entity
title: Routing
description: "Routing"
resource: http://127.0.0.1:8080/rest/e1/growerp.manufacturing.Routing
tags: [growerp, manufacturing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Routing

Routing

Full entity name: `growerp.manufacturing.Routing`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `routingId` | id | Y |  |
| `ownerPartyId` | id |  |  |
| `routingName` | text-medium |  |  |
| `description` | text-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`
- many [ProductRouting](ProductRouting.md) via `routingId`
- many [RoutingTask](RoutingTask.md) via `routingId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.manufacturing.Routing

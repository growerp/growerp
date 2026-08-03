---
type: Moqui Entity
title: RequestWorkEffort
description: "Request Work Effort"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestWorkEffort
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestWorkEffort

Request Work Effort

Full entity name: `mantle.request.RequestWorkEffort`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Request](Request.md) via `requestId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestWorkEffort

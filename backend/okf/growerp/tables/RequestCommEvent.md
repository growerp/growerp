---
type: Moqui Entity
title: RequestCommEvent
description: "Request Comm Event"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestCommEvent
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestCommEvent

Request Comm Event

Full entity name: `mantle.request.RequestCommEvent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestId` | id | Y |  |
| `communicationEventId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Request](Request.md) via `requestId`
- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestCommEvent

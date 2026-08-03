---
type: Moqui Entity
title: RequestNote
description: "Request Note"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestNote
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestNote

Request Note

Full entity name: `mantle.request.RequestNote`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestId` | id | Y |  |
| `noteDate` | date-time | Y |  |
| `requestItemSeqId` | id |  |  |
| `noteText` | text-very-long |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Request](Request.md) via `requestId`
- one-nofk [RequestItem](RequestItem.md) via `requestId`, `requestItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestNote

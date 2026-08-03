---
type: Moqui Entity
title: RequestItemAssoc
description: "Request Item Assoc"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestItemAssoc
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestItemAssoc

Request Item Assoc

Full entity name: `mantle.request.RequestItemAssoc`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestId` | id | Y |  |
| `requestItemSeqId` | id | Y |  |
| `otherRequestId` | id | Y |  |
| `otherRequestItemSeqId` | id | Y |  |
| `quantity` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [RequestItem](RequestItem.md) via `requestId`, `requestItemSeqId`
- one [Other RequestItem](RequestItem.md) via `otherRequestId`, `otherRequestItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestItemAssoc

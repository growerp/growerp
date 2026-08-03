---
type: Moqui Entity
title: RequestContent
description: "Request Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestContent
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestContent

Request Content

Full entity name: `mantle.request.RequestContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestContentId` | id | Y |  |
| `requestId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `contentTypeEnumId` | id |  |  |
| `contentDate` | date-time |  |  |
| `description` | text-long |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Request](Request.md) via `requestId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestContent

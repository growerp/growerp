---
type: Moqui Entity
title: WikiPageRequest
description: "Wiki Page Request"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.WikiPageRequest
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WikiPageRequest

Wiki Page Request

Full entity name: `mantle.request.WikiPageRequest`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `wikiPageId` | id | Y |  |
| `requestId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.resource.wiki.WikiPage` via `wikiPageId`
- one [Request](Request.md) via `requestId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.WikiPageRequest

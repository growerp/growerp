---
type: Moqui Entity
title: RequestCategory
description: "Request Category"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestCategory
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestCategory

Request Category

Full entity name: `mantle.request.RequestCategory`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestCategoryId` | id | Y |  |
| `parentCategoryId` | id |  |  |
| `responsiblePartyId` | id |  | Party (person or group) responsible for Requests in this Category. |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent RequestCategory](RequestCategory.md) via `parentCategoryId`
- one [Responsible Party](Party.md) via `responsiblePartyId`
- many [Request](Request.md) via `requestCategoryId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestCategory

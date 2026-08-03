---
type: Moqui Entity
title: WikiPageWorkEffort
description: "Wiki Page Work Effort"
resource: http://127.0.0.1:8080/rest/e1/mantle.work.effort.WikiPageWorkEffort
tags: [mantle, work, effort]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WikiPageWorkEffort

Wiki Page Work Effort

Full entity name: `mantle.work.effort.WikiPageWorkEffort`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `wikiPageId` | id | Y |  |
| `workEffortId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.resource.wiki.WikiPage` via `wikiPageId`
- one [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.work.effort.WikiPageWorkEffort

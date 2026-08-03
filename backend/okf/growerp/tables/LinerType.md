---
type: Moqui Entity
title: LinerType
description: "Liner Type"
resource: http://127.0.0.1:8080/rest/e1/growerp.liner.LinerType
tags: [growerp, liner]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# LinerType

Liner Type

Full entity name: `growerp.liner.LinerType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `linerTypeId` | id | Y |  |
| `ownerPartyId` | id |  |  |
| `linerName` | text-medium |  |  |
| `widthIncrement` | number-decimal |  |  |
| `linerWeight` | number-decimal |  |  |
| `rollStockWidth` | number-decimal |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`
- many [LinerPanel](LinerPanel.md) via `linerTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.liner.LinerType

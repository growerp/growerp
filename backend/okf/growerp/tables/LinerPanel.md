---
type: Moqui Entity
title: LinerPanel
description: "Liner Panel"
resource: http://127.0.0.1:8080/rest/e1/growerp.liner.LinerPanel
tags: [growerp, liner]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# LinerPanel

Liner Panel

Full entity name: `growerp.liner.LinerPanel`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `qcNum` | id | Y |  |
| `ownerPartyId` | id |  |  |
| `salesOrderId` | id |  |  |
| `workEffortId` | id |  |  |
| `linerTypeId` | id |  |  |
| `panelWidth` | number-decimal |  |  |
| `panelLength` | number-decimal |  |  |
| `panelName` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`
- one [LinerType](LinerType.md) via `linerTypeId`
- one-nofk [WorkEffort](WorkEffort.md) via `workEffortId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.liner.LinerPanel

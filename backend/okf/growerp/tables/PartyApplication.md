---
type: Moqui Entity
title: PartyApplication
description: "Party Application"
resource: http://127.0.0.1:8080/rest/e1/growerp.PartyApplication
tags: [growerp]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyApplication

Party Application

Full entity name: `growerp.PartyApplication`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `applicationId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [Application](Application.md) via `applicationId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.PartyApplication

---
type: Moqui Entity
title: EmplPositionClassParty
description: "An alternative to EmplPosition and Employment to represent an employee in a position class for billing purposes, etc. Can be used in addition to EmplPosition or instead of."
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClassParty
tags: [mantle, humanres, position]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplPositionClassParty

An alternative to EmplPosition and Employment to represent an employee in a position class for billing purposes, etc. Can be used in addition to EmplPosition or instead of.

Full entity name: `mantle.humanres.position.EmplPositionClassParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionClassId` | id | Y |  |
| `partyId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one [Party](Party.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClassParty

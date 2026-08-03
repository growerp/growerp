---
type: Moqui Entity
title: EmplPositionParty
description: "For manager, department/etc internal organization, etc; use Employment entity for employee"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionParty
tags: [mantle, humanres, position]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplPositionParty

For manager, department/etc internal organization, etc; use Employment entity for employee

Full entity name: `mantle.humanres.position.EmplPositionParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmplPosition](EmplPosition.md) via `emplPositionId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionParty

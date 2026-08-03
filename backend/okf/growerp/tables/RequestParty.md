---
type: Moqui Entity
title: RequestParty
description: "Request Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.RequestParty
tags: [mantle, request]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequestParty

Request Party

Full entity name: `mantle.request.RequestParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requestId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `receiveNotifications` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Request](Request.md) via `requestId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`
- one-nofk [Person](Person.md) via `partyId`
- one-nofk [Organization](Organization.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.RequestParty

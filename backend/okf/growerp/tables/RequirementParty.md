---
type: Moqui Entity
title: RequirementParty
description: "Requirement Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.requirement.RequirementParty
tags: [mantle, request, requirement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequirementParty

Requirement Party

Full entity name: `mantle.request.requirement.RequirementParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requirementId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Requirement](Requirement.md) via `requirementId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.requirement.RequirementParty

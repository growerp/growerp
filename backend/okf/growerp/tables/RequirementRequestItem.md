---
type: Moqui Entity
title: RequirementRequestItem
description: "Requirement Request Item"
resource: http://127.0.0.1:8080/rest/e1/mantle.request.requirement.RequirementRequestItem
tags: [mantle, request, requirement]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# RequirementRequestItem

Requirement Request Item

Full entity name: `mantle.request.requirement.RequirementRequestItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `requirementId` | id | Y |  |
| `requestId` | id | Y |  |
| `requestItemSeqId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Requirement](Requirement.md) via `requirementId`
- one [RequestItem](RequestItem.md) via `requestId`, `requestItemSeqId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.request.requirement.RequirementRequestItem

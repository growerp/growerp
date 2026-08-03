---
type: Moqui Entity
title: EmplClassResponsibility
description: "Empl Class Responsibility"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplClassResponsibility
tags: [mantle, humanres, position]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplClassResponsibility

Empl Class Responsibility

Full entity name: `mantle.humanres.position.EmplClassResponsibility`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionClassId` | id | Y |  |
| `responsibilityEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `comments` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one `moqui.basic.Enumeration` via `responsibilityEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplClassResponsibility

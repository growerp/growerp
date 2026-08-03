---
type: Moqui Entity
title: EmplPositionClassDimension
description: "Empl Position Class Dimension"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClassDimension
tags: [mantle, humanres, position]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplPositionClassDimension

Empl Position Class Dimension

Full entity name: `mantle.humanres.position.EmplPositionClassDimension`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionClassId` | id | Y |  |
| `uomDimensionTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one `moqui.basic.UomDimensionType` via `uomDimensionTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.position.EmplPositionClassDimension

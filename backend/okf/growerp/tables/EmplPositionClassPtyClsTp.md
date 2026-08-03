---
type: Moqui Entity
title: EmplPositionClassPtyClsTp
description: "Empl Position Class Pty Cls Tp"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.EmplPositionClassPtyClsTp
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmplPositionClassPtyClsTp

Empl Position Class Pty Cls Tp

Full entity name: `mantle.party.EmplPositionClassPtyClsTp`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emplPositionClassId` | id | Y |  |
| `classificationTypeEnumId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmplPositionClass](EmplPositionClass.md) via `emplPositionClassId`
- one `moqui.basic.Enumeration` via `classificationTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.EmplPositionClassPtyClsTp

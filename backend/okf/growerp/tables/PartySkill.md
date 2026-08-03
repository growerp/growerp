---
type: Moqui Entity
title: PartySkill
description: "Party Skill"
resource: http://127.0.0.1:8080/rest/e1/mantle.humanres.ability.PartySkill
tags: [mantle, humanres, ability]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartySkill

Party Skill

Full entity name: `mantle.humanres.ability.PartySkill`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `skillTypeEnumId` | id | Y |  |
| `rating` | number-integer |  |  |
| `skillLevel` | number-integer |  |  |
| `startedUsingDate` | date-time |  |  |
| `yearsExperience` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.basic.Enumeration` via `skillTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.humanres.ability.PartySkill

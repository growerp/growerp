---
type: Moqui Entity
title: PartySettingTypeRole
description: "Party Setting Type Role"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartySettingTypeRole
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartySettingTypeRole

Party Setting Type Role

Full entity name: `mantle.party.PartySettingTypeRole`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partySettingTypeId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PartySettingType](PartySettingType.md) via `partySettingTypeId`
- one [RoleType](RoleType.md) via `roleTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartySettingTypeRole

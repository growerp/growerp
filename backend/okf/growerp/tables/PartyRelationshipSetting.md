---
type: Moqui Entity
title: PartyRelationshipSetting
description: "Party Relationship Setting"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyRelationshipSetting
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyRelationshipSetting

Party Relationship Setting

Full entity name: `mantle.party.PartyRelationshipSetting`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyRelationshipId` | id | Y |  |
| `partySettingTypeId` | id | Y |  |
| `settingValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [PartyRelationship](PartyRelationship.md) via `partyRelationshipId`
- one [PartySettingType](PartySettingType.md) via `partySettingTypeId`
- one-nofk `moqui.basic.Enumeration` via `settingValue`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyRelationshipSetting

---
type: Moqui Entity
title: PartySettingType
description: "Party Setting Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartySettingType
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartySettingType

Party Setting Type

Full entity name: `mantle.party.PartySettingType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partySettingTypeId` | id | Y |  |
| `description` | text-medium |  |  |
| `validRegexp` | text-medium |  | For non-enum settings, regexp to validate |
| `enumTypeId` | id |  |  |
| `defaultValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.EnumerationType` via `enumTypeId`
- many [PartySettingTypeRole](PartySettingTypeRole.md) via `partySettingTypeId`
- many [PartyRelationshipSetting](PartyRelationshipSetting.md) via `partySettingTypeId`
- many [PartySetting](PartySetting.md) via `partySettingTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartySettingType

---
type: Moqui Entity
title: PartySetting
description: "Party Setting"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartySetting
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartySetting

Party Setting

Full entity name: `mantle.party.PartySetting`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `partySettingTypeId` | id | Y |  |
| `settingValue` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [PartySettingType](PartySettingType.md) via `partySettingTypeId`
- one-nofk `moqui.basic.Enumeration` via `settingValue`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartySetting

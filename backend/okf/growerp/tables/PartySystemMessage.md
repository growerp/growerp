---
type: Moqui Entity
title: PartySystemMessage
description: "Party System Message"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartySystemMessage
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartySystemMessage

Party System Message

Full entity name: `mantle.party.PartySystemMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `systemMessageId` | id | Y |  |
| `partyIdTypeEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.service.message.SystemMessage` via `systemMessageId`
- one `moqui.basic.Enumeration` via `partyIdTypeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartySystemMessage

---
type: Moqui Entity
title: CommunicationEventParty
description: "Communication Event Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventParty
tags: [mantle, party, communication]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CommunicationEventParty

Communication Event Party

Full entity name: `mantle.party.communication.CommunicationEventParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `communicationEventId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `contactMechId` | id |  |  |
| `statusId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`
- one [Party](Party.md) via `partyId`
- one-nofk [Person](Person.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`
- one [ContactMech](ContactMech.md) via `contactMechId`
- one `moqui.basic.StatusItem` via `statusId`
- many `moqui.security.UserAccount` via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventParty

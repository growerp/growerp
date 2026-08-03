---
type: Moqui Entity
title: CommunicationEvent
description: "Communication Event"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEvent
tags: [mantle, party, communication]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CommunicationEvent

Communication Event

Full entity name: `mantle.party.communication.CommunicationEvent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `communicationEventId` | id | Y |  |
| `communicationEventTypeId` | id |  |  |
| `contactMechTypeEnumId` | id |  |  |
| `statusId` | id |  |  |
| `parentCommEventId` | id |  |  |
| `rootCommEventId` | id |  |  |
| `fromContactMechId` | id |  |  |
| `toContactMechId` | id |  |  |
| `fromPartyId` | id |  |  |
| `fromRoleTypeId` | id |  |  |
| `toPartyId` | id |  |  |
| `toRoleTypeId` | id |  |  |
| `entryDate` | date-time |  |  |
| `datetimeStarted` | date-time |  |  |
| `datetimeEnded` | date-time |  |  |
| `subject` | text-long |  |  |
| `contentType` | text-medium |  |  |
| `body` | text-very-long |  |  |
| `note` | text-long |  |  |
| `reasonEnumId` | id |  |  |
| `contactListId` | id |  |  |
| `emailMessageId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [CommunicationEventType](CommunicationEventType.md) via `communicationEventTypeId`
- one `moqui.basic.Enumeration` via `contactMechTypeEnumId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Parent CommunicationEvent](CommunicationEvent.md) via `parentCommEventId`
- many [Child CommunicationEvent](CommunicationEvent.md) via `communicationEventId`
- one [Root CommunicationEvent](CommunicationEvent.md) via `rootCommEventId`
- one [From ContactMech](ContactMech.md) via `fromContactMechId`
- one [To ContactMech](ContactMech.md) via `toContactMechId`
- one [From Party](Party.md) via `fromPartyId`
- many `moqui.security.UserAccount` via `fromPartyId`
- one [From RoleType](RoleType.md) via `fromRoleTypeId`
- one [To Party](Party.md) via `toPartyId`
- many `moqui.security.UserAccount` via `toPartyId`
- one [To RoleType](RoleType.md) via `toRoleTypeId`
- one [ContactList](ContactList.md) via `contactListId`
- one `moqui.basic.Enumeration` via `reasonEnumId`
- many [CommunicationEventContent](CommunicationEventContent.md) via `communicationEventId`
- many [CommunicationEventParty](CommunicationEventParty.md) via `communicationEventId`
- many [CommunicationEventProduct](CommunicationEventProduct.md) via `communicationEventId`
- many [CommunicationEventPurpose](CommunicationEventPurpose.md) via `communicationEventId`
- many [OrderCommunicationEvent](OrderCommunicationEvent.md) via `communicationEventId`
- many [ContactListCommStatus](ContactListCommStatus.md) via `communicationEventId`
- many [WikiPageCommunicationEvent](WikiPageCommunicationEvent.md) via `communicationEventId`
- many [SubscriptionDelivery](SubscriptionDelivery.md) via `communicationEventId`
- many [RequestCommEvent](RequestCommEvent.md) via `communicationEventId`
- many [PartyNeed](PartyNeed.md) via `communicationEventId`
- many [WorkEffortCommEvent](WorkEffortCommEvent.md) via `communicationEventId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEvent

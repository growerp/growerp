---
type: Moqui Entity
title: CommunicationEventType
description: "Communication Event Type"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventType
tags: [mantle, party, communication]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CommunicationEventType

Communication Event Type

Full entity name: `mantle.party.communication.CommunicationEventType`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `communicationEventTypeId` | id | Y |  |
| `parentTypeId` | id |  |  |
| `description` | text-medium |  |  |
| `contactMechTypeEnumId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Parent CommunicationEventType](CommunicationEventType.md) via `parentTypeId`
- one `moqui.basic.Enumeration` via `contactMechTypeEnumId`
- many [CommunicationEvent](CommunicationEvent.md) via `communicationEventTypeId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventType

---
type: Moqui Entity
title: CommunicationEventContent
description: "Communication Event Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventContent
tags: [mantle, party, communication]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CommunicationEventContent

Communication Event Content

Full entity name: `mantle.party.communication.CommunicationEventContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `communicationEventContentId` | id | Y |  |
| `communicationEventId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `contentTypeEnumId` | id |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `userId` | id |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.security.UserAccount` via `userId`
- one `moqui.basic.Enumeration` via `contentTypeEnumId`
- many [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventContent

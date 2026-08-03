---
type: Moqui Entity
title: WikiPageCommunicationEvent
description: "Wiki Page Communication Event"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.communication.WikiPageCommunicationEvent
tags: [mantle, party, communication]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WikiPageCommunicationEvent

Wiki Page Communication Event

Full entity name: `mantle.party.communication.WikiPageCommunicationEvent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `wikiPageId` | id | Y |  |
| `communicationEventId` | id | Y |  |
| `description` | text-medium |  |  |
| `sequenceNum` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.resource.wiki.WikiPage` via `wikiPageId`
- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.communication.WikiPageCommunicationEvent

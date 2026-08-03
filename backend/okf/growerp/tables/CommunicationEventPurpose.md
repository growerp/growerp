---
type: Moqui Entity
title: CommunicationEventPurpose
description: "Communication Event Purpose"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventPurpose
tags: [mantle, party, communication]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CommunicationEventPurpose

Communication Event Purpose

Full entity name: `mantle.party.communication.CommunicationEventPurpose`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `communicationEventId` | id | Y |  |
| `purposeEnumId` | id | Y |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`
- one `moqui.basic.Enumeration` via `purposeEnumId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventPurpose

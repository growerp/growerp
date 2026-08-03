---
type: Moqui Entity
title: CommunicationEventProduct
description: "Communication Event Product"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventProduct
tags: [mantle, party, communication]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CommunicationEventProduct

Communication Event Product

Full entity name: `mantle.party.communication.CommunicationEventProduct`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `productId` | id | Y |  |
| `communicationEventId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Product](Product.md) via `productId`
- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.communication.CommunicationEventProduct

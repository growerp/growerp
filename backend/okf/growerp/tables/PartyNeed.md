---
type: Moqui Entity
title: PartyNeed
description: "Party Need"
resource: http://127.0.0.1:8080/rest/e1/mantle.sales.need.PartyNeed
tags: [mantle, sales, need]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyNeed

Party Need

Full entity name: `mantle.sales.need.PartyNeed`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyNeedId` | id | Y |  |
| `needTypeEnumId` | id |  |  |
| `partyId` | id |  |  |
| `roleTypeId` | id |  |  |
| `communicationEventId` | id |  |  |
| `productId` | id |  |  |
| `productCategoryId` | id |  |  |
| `visitId` | id |  |  |
| `datetimeRecorded` | date-time |  |  |
| `description` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `needTypeEnumId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`
- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`
- one [Product](Product.md) via `productId`
- one [ProductCategory](ProductCategory.md) via `productCategoryId`
- one `moqui.server.Visit` via `visitId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.sales.need.PartyNeed

---
type: Moqui Entity
title: PartyContent
description: "Party Content"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyContent
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyContent

Party Content

Full entity name: `mantle.party.PartyContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyContentId` | id | Y |  |
| `partyId` | id |  |  |
| `contentLocation` | text-medium |  |  |
| `partyContentTypeEnumId` | id |  |  |
| `description` | text-long |  |  |
| `contentDate` | date-time |  |  |
| `viewedDate` | date-time |  |  |
| `userId` | id |  |  |
| `partyIdTypeEnumId` | id |  |  |
| `originalPartyContentId` | id |  | Set this when copying content from one Party to another, may have same or different contentLocation |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.basic.Enumeration` via `partyContentTypeEnumId`
- one `moqui.basic.Enumeration` via `partyIdTypeEnumId`
- one [Original PartyContent](PartyContent.md) via `originalPartyContentId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyContent

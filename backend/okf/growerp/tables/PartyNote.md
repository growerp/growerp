---
type: Moqui Entity
title: PartyNote
description: "Party Note"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyNote
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyNote

Party Note

Full entity name: `mantle.party.PartyNote`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `noteDate` | date-time | Y |  |
| `noteText` | text-long |  |  |
| `internalNote` | text-indicator |  |  |
| `userId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.security.UserAccount` via `userId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyNote

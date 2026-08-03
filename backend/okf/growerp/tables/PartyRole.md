---
type: Moqui Entity
title: PartyRole
description: "Party Role"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyRole
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyRole

Party Role

Full entity name: `mantle.party.PartyRole`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`
- many [Vendor OrderPart](OrderPart.md) via `partyId`
- many [From Invoice](Invoice.md) via `partyId`
- many [To Invoice](Invoice.md) via `partyId`
- many [Customer OrderPart](OrderPart.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyRole

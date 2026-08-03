---
type: Moqui Entity
title: PartyRelationship
description: "Party Relationship"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.PartyRelationship
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyRelationship

Party Relationship

Full entity name: `mantle.party.PartyRelationship`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyRelationshipId` | id | Y |  |
| `relationshipTypeEnumId` | id |  |  |
| `fromPartyId` | id |  |  |
| `fromRoleTypeId` | id |  |  |
| `toPartyId` | id |  |  |
| `toRoleTypeId` | id |  |  |
| `fromDate` | date-time |  |  |
| `thruDate` | date-time |  |  |
| `statusId` | id |  |  |
| `comments` | text-medium |  |  |
| `relationshipName` | text-medium |  | Official name of relationship, such as title in an organization. |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `relationshipTypeEnumId`
- one [From Party](Party.md) via `fromPartyId`
- one [From RoleType](RoleType.md) via `fromRoleTypeId`
- one [To Party](Party.md) via `toPartyId`
- one [To RoleType](RoleType.md) via `toRoleTypeId`
- one `moqui.basic.StatusItem` via `statusId`
- one-nofk [Employment](Employment.md) via `partyRelationshipId`
- many [PartyRelationshipSetting](PartyRelationshipSetting.md) via `partyRelationshipId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.PartyRelationship

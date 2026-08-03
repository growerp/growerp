---
type: Moqui Entity
title: Person
description: "Person"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.Person
tags: [mantle, party]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Person

Person

Full entity name: `mantle.party.Person`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `salutation` | text-medium |  |  |
| `firstName` | text-medium |  |  |
| `middleName` | text-medium |  |  |
| `lastName` | text-medium |  |  |
| `personalTitle` | text-medium |  |  |
| `suffix` | text-medium |  |  |
| `nickname` | text-medium |  |  |
| `gender` | text-indicator |  |  |
| `birthDate` | date |  |  |
| `deceasedDate` | date |  |  |
| `height` | number-float |  |  |
| `weight` | number-float |  |  |
| `mothersMaidenName` | text-medium |  |  |
| `maritalStatusEnumId` | id |  |  |
| `employmentStatusEnumId` | id |  |  |
| `residenceStatusEnumId` | id |  |  |
| `occupation` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one `moqui.basic.Enumeration` via `maritalStatusEnumId`
- one `moqui.basic.Enumeration` via `employmentStatusEnumId`
- one `moqui.basic.Enumeration` via `residenceStatusEnumId`
- many [From Invoice](Invoice.md) via `partyId`
- many [To Invoice](Invoice.md) via `partyId`
- many [Owner Facility](Facility.md) via `partyId`
- many [OrderItemParty](OrderItemParty.md) via `partyId`
- many [OrderPartParty](OrderPartParty.md) via `partyId`
- many [CommunicationEventParty](CommunicationEventParty.md) via `partyId`
- many [RequestParty](RequestParty.md) via `partyId`
- many [From Shipment](Shipment.md) via `partyId`
- many [To Shipment](Shipment.md) via `partyId`
- many [WorkEffortParty](WorkEffortParty.md) via `partyId`
- many [TimeEntry](TimeEntry.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.Person

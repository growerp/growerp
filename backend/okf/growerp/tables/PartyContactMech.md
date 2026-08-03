---
type: Moqui Entity
title: PartyContactMech
description: "Party Contact Mech"
resource: http://127.0.0.1:8080/rest/e1/mantle.party.contact.PartyContactMech
tags: [mantle, party, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PartyContactMech

Party Contact Mech

Full entity name: `mantle.party.contact.PartyContactMech`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `partyId` | id | Y |  |
| `contactMechId` | id | Y |  |
| `contactMechPurposeId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `extension` | text-short |  |  |
| `comments` | text-medium |  |  |
| `allowSolicitation` | text-indicator |  |  |
| `usedSince` | date |  |  |
| `usedUntil` | date |  |  |
| `verifyCode` | text-medium |  |  |
| `verifyCodeDate` | date-time |  |  |
| `verifyCodeAttempts` | number-integer |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `partyId`
- one [ContactMech](ContactMech.md) via `contactMechId`
- one [ContactMechPurpose](ContactMechPurpose.md) via `contactMechPurposeId`
- one-nofk [PostalAddress](PostalAddress.md) via `contactMechId`
- one-nofk [TelecomNumber](TelecomNumber.md) via `contactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.party.contact.PartyContactMech

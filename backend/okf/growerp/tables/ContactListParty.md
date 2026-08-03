---
type: Moqui Entity
title: ContactListParty
description: "Contact List Party"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.contact.ContactListParty
tags: [mantle, marketing, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ContactListParty

Contact List Party

Full entity name: `mantle.marketing.contact.ContactListParty`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `contactListId` | id | Y |  |
| `partyId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `statusId` | id |  |  |
| `preferredContactMechId` | id |  |  |
| `optInVerifyCode` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ContactList](ContactList.md) via `contactListId`
- one [Party](Party.md) via `partyId`
- one `moqui.basic.StatusItem` via `statusId`
- one [Preferred ContactMech](ContactMech.md) via `preferredContactMechId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.contact.ContactListParty

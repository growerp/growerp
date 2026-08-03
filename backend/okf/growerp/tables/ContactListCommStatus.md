---
type: Moqui Entity
title: ContactListCommStatus
description: "Contact List Comm Status"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.contact.ContactListCommStatus
tags: [mantle, marketing, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ContactListCommStatus

Contact List Comm Status

Full entity name: `mantle.marketing.contact.ContactListCommStatus`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `contactListId` | id | Y |  |
| `communicationEventId` | id | Y |  |
| `contactMechId` | id | Y |  |
| `partyId` | id |  |  |
| `messageId` | text-medium |  |  |
| `statusId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ContactList](ContactList.md) via `contactListId`
- one [CommunicationEvent](CommunicationEvent.md) via `communicationEventId`
- one [ContactMech](ContactMech.md) via `contactMechId`
- one [Party](Party.md) via `partyId`
- one `moqui.basic.StatusItem` via `statusId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.contact.ContactListCommStatus

---
type: Moqui Entity
title: ContactList
description: "Contact List"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.contact.ContactList
tags: [mantle, marketing, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ContactList

Contact List

Full entity name: `mantle.marketing.contact.ContactList`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `contactListId` | id | Y |  |
| `contactListTypeEnumId` | id |  |  |
| `contactMechTypeEnumId` | id |  |  |
| `marketingCampaignId` | id |  |  |
| `contactListName` | text-medium |  |  |
| `description` | text-medium |  |  |
| `comments` | text-medium |  |  |
| `isPublic` | text-indicator |  |  |
| `singleUse` | text-indicator |  | Parties in the list should be contacted only once. |
| `ownerPartyId` | id |  |  |
| `verifyEmailFrom` | text-medium |  |  |
| `verifyEmailScreen` | text-medium |  |  |
| `verifyEmailSubject` | text-long |  |  |
| `verifyEmailWebSiteId` | id |  |  |
| `optOutScreen` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketingCampaign](MarketingCampaign.md) via `marketingCampaignId`
- one `moqui.basic.Enumeration` via `contactListTypeEnumId`
- one `moqui.basic.Enumeration` via `contactMechTypeEnumId`
- one [Owner Party](Party.md) via `ownerPartyId`
- many [ContactListCommStatus](ContactListCommStatus.md) via `contactListId`
- many [ContactListEmail](ContactListEmail.md) via `contactListId`
- many [ContactListParty](ContactListParty.md) via `contactListId`
- many [CommunicationEvent](CommunicationEvent.md) via `contactListId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.contact.ContactList

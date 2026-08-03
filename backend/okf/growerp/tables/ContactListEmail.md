---
type: Moqui Entity
title: ContactListEmail
description: "Contact List Email"
resource: http://127.0.0.1:8080/rest/e1/mantle.marketing.contact.ContactListEmail
tags: [mantle, marketing, contact]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ContactListEmail

Contact List Email

Full entity name: `mantle.marketing.contact.ContactListEmail`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `contactListId` | id | Y |  |
| `emailTypeEnumId` | id | Y |  |
| `fromDate` | date-time | Y |  |
| `thruDate` | date-time |  |  |
| `emailTemplateId` | id |  |  |
| `wikiPageCategoryId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ContactList](ContactList.md) via `contactListId`
- one `moqui.basic.Enumeration` via `emailTypeEnumId`
- one `moqui.basic.email.EmailTemplate` via `emailTemplateId`
- one `moqui.resource.wiki.WikiPageCategory` via `wikiPageCategoryId`
- many `moqui.resource.wiki.WikiBlogCategory`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.marketing.contact.ContactListEmail

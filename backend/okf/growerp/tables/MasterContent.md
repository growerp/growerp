---
type: Moqui Entity
title: MasterContent
description: "Platform-neutral content authored once, then adapted per platform into SocialPost (broadcast) or OutreachMessage (1:1) children."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.MasterContent
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MasterContent

Platform-neutral content authored once, then adapted per platform into SocialPost (broadcast) or OutreachMessage (1:1) children.

Full entity name: `growerp.marketing.MasterContent`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `masterContentId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `planId` | id |  |  |
| `contentType` | text-short |  |  |
| `pnpType` | text-short |  |  |
| `title` | text-medium |  |  |
| `body` | text-very-long |  |  |
| `callToAction` | text-long |  |  |
| `targetUrl` | text-medium |  |  |
| `status` | text-short |  |  |
| `approvedDate` | date-time |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ContentPlan](ContentPlan.md) via `planId`
- one [Party](Party.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.MasterContent

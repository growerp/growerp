---
type: Moqui Entity
title: SocialPost
description: "Represents a specific social media post."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.SocialPost
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SocialPost

Represents a specific social media post.

Full entity name: `growerp.marketing.SocialPost`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `postId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `planId` | id |  |  |
| `type` | text-short |  |  |
| `platform` | text-short |  |  |
| `masterContentId` | id |  |  |
| `headline` | text-medium |  |  |
| `draftContent` | text-very-long |  |  |
| `finalContent` | text-very-long |  |  |
| `status` | text-short |  |  |
| `scheduledDate` | date-time |  |  |
| `publishedDate` | date-time |  |  |
| `publishedUrl` | text-medium |  |  |
| `externalPostId` | text-short |  |  |
| `publishError` | text-long |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [ContentPlan](ContentPlan.md) via `planId`
- one [Party](Party.md) via `ownerPartyId`
- many [SocialEngagement](SocialEngagement.md) via `postId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.SocialPost

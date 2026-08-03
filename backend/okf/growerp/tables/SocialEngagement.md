---
type: Moqui Entity
title: SocialEngagement
description: "A signal of interest on a social post; converting it creates a Lead and a follow-up Activity."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.SocialEngagement
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SocialEngagement

A signal of interest on a social post; converting it creates a Lead and a follow-up Activity.

Full entity name: `growerp.marketing.SocialEngagement`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `engagementId` | id | Y |  |
| `ownerPartyId` | id |  |  |
| `postId` | id |  |  |
| `platform` | text-short |  |  |
| `engagementType` | text-short |  |  |
| `userName` | text-medium |  |  |
| `userProfileUrl` | text-medium |  |  |
| `externalEngagementId` | text-medium |  |  |
| `note` | text-long |  |  |
| `status` | text-short |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [SocialPost](SocialPost.md) via `postId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.SocialEngagement

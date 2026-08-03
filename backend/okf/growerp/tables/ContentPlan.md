---
type: Moqui Entity
title: ContentPlan
description: "Represents a weekly content plan based on the Pain-News-Prize formula."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.ContentPlan
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ContentPlan

Represents a weekly content plan based on the Pain-News-Prize formula.

Full entity name: `growerp.marketing.ContentPlan`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `planId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `personaId` | id |  |  |
| `weekStartDate` | date-time |  |  |
| `theme` | text-medium |  |  |
| `status` | text-short |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketingPersona](MarketingPersona.md) via `personaId`
- one [Party](Party.md) via `ownerPartyId`
- many [MasterContent](MasterContent.md) via `planId`
- many [SocialPost](SocialPost.md) via `planId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.ContentPlan

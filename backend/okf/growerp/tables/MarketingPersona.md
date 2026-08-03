---
type: Moqui Entity
title: MarketingPersona
description: "Represents a target customer avatar/persona for AI content generation."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.MarketingPersona
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MarketingPersona

Represents a target customer avatar/persona for AI content generation.

Full entity name: `growerp.marketing.MarketingPersona`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `personaId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `name` | text-medium |  |  |
| `demographics` | text-long |  |  |
| `painPoints` | text-long |  |  |
| `goals` | text-long |  |  |
| `toneOfVoice` | text-long |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `ownerPartyId`
- many [Course](Course.md) via `personaId`
- many [ContentPlan](ContentPlan.md) via `personaId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.MarketingPersona

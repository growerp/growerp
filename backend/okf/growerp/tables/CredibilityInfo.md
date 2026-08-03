---
type: Moqui Entity
title: CredibilityInfo
description: "Credibility Info"
resource: http://127.0.0.1:8080/rest/e1/growerp.landing.CredibilityInfo
tags: [growerp, landing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CredibilityInfo

Credibility Info

Full entity name: `growerp.landing.CredibilityInfo`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `credibilityInfoId` | id | Y |  |
| `pseudoId` | id |  |  |
| `landingPageId` | id |  |  |
| `creatorBio` | text-very-long |  |  |
| `backgroundText` | text-very-long |  |  |
| `creatorImageUrl` | text-long |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [LandingPage LandingPage](LandingPage.md) via `landingPageId`
- many [CredibilityInfo CredibilityStatistic](CredibilityStatistic.md) via `credibilityInfoId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.landing.CredibilityInfo

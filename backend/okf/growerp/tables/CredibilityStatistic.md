---
type: Moqui Entity
title: CredibilityStatistic
description: "Credibility Statistic"
resource: http://127.0.0.1:8080/rest/e1/growerp.landing.CredibilityStatistic
tags: [growerp, landing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CredibilityStatistic

Credibility Statistic

Full entity name: `growerp.landing.CredibilityStatistic`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `credibilityStatisticId` | id | Y |  |
| `pseudoId` | id |  |  |
| `credibilityInfoId` | id |  |  |
| `statistic` | text-long |  |  |
| `sequence` | number-integer |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [CredibilityInfo CredibilityInfo](CredibilityInfo.md) via `credibilityInfoId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.landing.CredibilityStatistic

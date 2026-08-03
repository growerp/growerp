---
type: Moqui Entity
title: ScoringThreshold
description: "Scoring Threshold"
resource: http://127.0.0.1:8080/rest/e1/growerp.assessment.ScoringThreshold
tags: [growerp, assessment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# ScoringThreshold

Scoring Threshold

Full entity name: `growerp.assessment.ScoringThreshold`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `scoringThresholdId` | id | Y |  |
| `pseudoId` | id |  |  |
| `assessmentId` | id |  |  |
| `minScore` | number-decimal |  |  |
| `maxScore` | number-decimal |  |  |
| `leadStatus` | text-short |  |  |
| `description` | text-medium |  |  |
| `createdDate` | date-time |  |  |
| `createdByUserLogin` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Assessment Assessment](Assessment.md) via `assessmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.assessment.ScoringThreshold

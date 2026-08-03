---
type: Moqui Entity
title: Assessment
description: "Assessment"
resource: http://127.0.0.1:8080/rest/e1/growerp.assessment.Assessment
tags: [growerp, assessment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Assessment

Assessment

Full entity name: `growerp.assessment.Assessment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assessmentId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `companyPartyId` | id |  |  |
| `assessmentName` | text-medium |  |  |
| `description` | text-long |  |  |
| `status` | text-short |  |  |
| `createdDate` | date-time |  |  |
| `createdByUserLogin` | text-short |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastModifiedByUserLogin` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`
- one [Company Party](Party.md) via `companyPartyId`
- many [Application](Application.md) via `assessmentId`
- many [Assessment AssessmentQuestion](AssessmentQuestion.md) via `assessmentId`
- many [Assessment AssessmentResult](AssessmentResult.md) via `assessmentId`
- many [Assessment ScoringThreshold](ScoringThreshold.md) via `assessmentId`
- many [Assessment LandingPage](LandingPage.md) via `assessmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.assessment.Assessment

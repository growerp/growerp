---
type: Moqui Entity
title: AssessmentResult
description: "Assessment Result"
resource: http://127.0.0.1:8080/rest/e1/growerp.assessment.AssessmentResult
tags: [growerp, assessment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssessmentResult

Assessment Result

Full entity name: `growerp.assessment.AssessmentResult`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assessmentResultId` | id | Y |  |
| `pseudoId` | id |  |  |
| `assessmentId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `score` | number-decimal |  |  |
| `leadStatus` | text-short |  |  |
| `respondentName` | text-short |  |  |
| `respondentEmail` | text-medium |  |  |
| `respondentPhone` | text-short |  |  |
| `respondentCompany` | text-medium |  |  |
| `capturedLeadId` | id |  |  |
| `resultData` | text-very-long |  |  |
| `answersData` | text-very-long |  |  |
| `createdDate` | date-time |  |  |
| `createdByUserLogin` | text-short |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Assessment Assessment](Assessment.md) via `assessmentId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.assessment.AssessmentResult

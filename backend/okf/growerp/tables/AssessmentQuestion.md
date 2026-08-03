---
type: Moqui Entity
title: AssessmentQuestion
description: "Assessment Question"
resource: http://127.0.0.1:8080/rest/e1/growerp.assessment.AssessmentQuestion
tags: [growerp, assessment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssessmentQuestion

Assessment Question

Full entity name: `growerp.assessment.AssessmentQuestion`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assessmentQuestionId` | id | Y |  |
| `pseudoId` | id |  |  |
| `assessmentId` | id |  |  |
| `questionSequence` | number-integer |  |  |
| `questionType` | text-short |  |  |
| `questionText` | text-long |  |  |
| `questionDescription` | text-long |  |  |
| `isRequired` | text-indicator |  |  |
| `defaultOption` | id |  |  |
| `defaultValue` | text-long |  |  |
| `createdDate` | date-time |  |  |
| `createdByUserLogin` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Assessment Assessment](Assessment.md) via `assessmentId`
- many [AssessmentQuestion AssessmentQuestionOption](AssessmentQuestionOption.md) via `assessmentQuestionId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.assessment.AssessmentQuestion

---
type: Moqui Entity
title: AssessmentQuestionOption
description: "Assessment Question Option"
resource: http://127.0.0.1:8080/rest/e1/growerp.assessment.AssessmentQuestionOption
tags: [growerp, assessment]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# AssessmentQuestionOption

Assessment Question Option

Full entity name: `growerp.assessment.AssessmentQuestionOption`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `assessmentQuestionOptionId` | id | Y |  |
| `pseudoId` | id |  |  |
| `assessmentQuestionId` | id |  |  |
| `assessmentId` | id |  |  |
| `optionSequence` | number-integer |  |  |
| `optionText` | text-medium |  |  |
| `optionScore` | number-decimal |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [AssessmentQuestion AssessmentQuestion](AssessmentQuestion.md) via `assessmentQuestionId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.assessment.AssessmentQuestionOption

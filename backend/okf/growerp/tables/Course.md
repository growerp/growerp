---
type: Moqui Entity
title: Course
description: "Central course definition with title, objectives, and target audience."
resource: http://127.0.0.1:8080/rest/e1/growerp.course.Course
tags: [growerp, course]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# Course

Central course definition with title, objectives, and target audience.

Full entity name: `growerp.course.Course`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `courseId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `title` | text-medium |  |  |
| `description` | text-very-long |  |  |
| `objectives` | text-very-long |  |  |
| `targetPersonaId` | id |  |  |
| `difficulty` | text-short |  |  |
| `estimatedDuration` | number-integer |  |  |
| `status` | text-short |  |  |
| `coverImageUrl` | text-long |  |  |
| `productId` | id |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `createdByUserLogin` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `ownerPartyId`
- one [Course Product](Product.md) via `productId`
- one [MarketingPersona](MarketingPersona.md) via `targetPersonaId`
- many [CourseModule](CourseModule.md) via `courseId`
- many [CourseLesson](CourseLesson.md) via `courseId`
- many [CourseMedia](CourseMedia.md) via `courseId`
- many [CourseProgress](CourseProgress.md) via `courseId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.course.Course

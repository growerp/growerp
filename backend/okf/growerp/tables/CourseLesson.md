---
type: Moqui Entity
title: CourseLesson
description: "Individual lesson with content, key points, and media."
resource: http://127.0.0.1:8080/rest/e1/growerp.course.CourseLesson
tags: [growerp, course]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CourseLesson

Individual lesson with content, key points, and media.

Full entity name: `growerp.course.CourseLesson`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `lessonId` | id | Y |  |
| `pseudoId` | id |  |  |
| `moduleId` | id |  |  |
| `courseId` | id |  |  |
| `title` | text-medium |  |  |
| `content` | text-very-long |  |  |
| `keyPoints` | text-very-long |  |  |
| `sequenceNum` | number-integer |  |  |
| `estimatedDuration` | number-integer |  |  |
| `videoUrl` | text-long |  |  |
| `imageUrl` | text-long |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [CourseModule](CourseModule.md) via `moduleId`
- one [Course](Course.md) via `courseId`
- many [CourseMedia](CourseMedia.md) via `lessonId`
- many [CourseProgress](CourseProgress.md) via `lessonId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.course.CourseLesson

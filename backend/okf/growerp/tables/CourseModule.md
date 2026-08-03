---
type: Moqui Entity
title: CourseModule
description: "Module grouping related lessons within a course."
resource: http://127.0.0.1:8080/rest/e1/growerp.course.CourseModule
tags: [growerp, course]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CourseModule

Module grouping related lessons within a course.

Full entity name: `growerp.course.CourseModule`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `moduleId` | id | Y |  |
| `pseudoId` | id |  |  |
| `courseId` | id |  |  |
| `title` | text-medium |  |  |
| `description` | text-long |  |  |
| `sequenceNum` | number-integer |  |  |
| `estimatedDuration` | number-integer |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Course](Course.md) via `courseId`
- many [CourseLesson](CourseLesson.md) via `moduleId`
- many [CourseMedia](CourseMedia.md) via `moduleId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.course.CourseModule

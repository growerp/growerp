---
type: Moqui Entity
title: CourseProgress
description: "Tracks user progress through a course."
resource: http://127.0.0.1:8080/rest/e1/growerp.course.CourseProgress
tags: [growerp, course]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CourseProgress

Tracks user progress through a course.

Full entity name: `growerp.course.CourseProgress`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `progressId` | id | Y |  |
| `userId` | id |  |  |
| `courseId` | id |  |  |
| `currentLessonId` | id |  |  |
| `completedLessons` | text-very-long |  |  |
| `progressPercent` | number-integer |  |  |
| `startedDate` | date-time |  |  |
| `lastAccessDate` | date-time |  |  |
| `completedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.security.UserAccount` via `userId`
- one [Course](Course.md) via `courseId`
- one [CourseLesson](CourseLesson.md) via `currentLessonId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.course.CourseProgress

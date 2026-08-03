---
type: Moqui Entity
title: CourseMedia
description: "AI-generated content for various platforms."
resource: http://127.0.0.1:8080/rest/e1/growerp.course.CourseMedia
tags: [growerp, course]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# CourseMedia

AI-generated content for various platforms.

Full entity name: `growerp.course.CourseMedia`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `mediaId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `courseId` | id |  |  |
| `moduleId` | id |  |  |
| `lessonId` | id |  |  |
| `platform` | text-short |  |  |
| `mediaType` | text-short |  |  |
| `title` | text-medium |  |  |
| `generatedContent` | text-very-long |  |  |
| `editedContent` | text-very-long |  |  |
| `status` | text-short |  |  |
| `scheduledDate` | date-time |  |  |
| `publishedDate` | date-time |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Course](Course.md) via `courseId`
- one [CourseModule](CourseModule.md) via `moduleId`
- one [CourseLesson](CourseLesson.md) via `lessonId`
- one [Party](Party.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.course.CourseMedia

---
type: Moqui Entity
title: PageSection
description: "Page Section"
resource: http://127.0.0.1:8080/rest/e1/growerp.landing.PageSection
tags: [growerp, landing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PageSection

Page Section

Full entity name: `growerp.landing.PageSection`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `pageSectionId` | id | Y |  |
| `pseudoId` | id |  |  |
| `landingPageId` | id |  |  |
| `sectionSequence` | number-integer |  |  |
| `sectionTitle` | text-medium |  |  |
| `sectionDescription` | text-long |  |  |
| `sectionImageUrl` | text-long |  |  |
| `sectionType` | text-short |  |  |
| `contentJson` | text-very-long |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [LandingPage LandingPage](LandingPage.md) via `landingPageId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.landing.PageSection

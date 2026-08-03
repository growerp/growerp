---
type: Moqui Entity
title: WebsiteFormSubmission
description: "A visitor submission of a website form; partyId is the created/matched Lead."
resource: http://127.0.0.1:8080/rest/e1/growerp.website.WebsiteFormSubmission
tags: [growerp, website]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WebsiteFormSubmission

A visitor submission of a website form; partyId is the created/matched Lead.

Full entity name: `growerp.website.WebsiteFormSubmission`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `submissionId` | id | Y |  |
| `formId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `partyId` | id |  |  |
| `submittedDate` | date-time |  |  |
| `valuesJson` | text-very-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WebsiteForm](WebsiteForm.md) via `formId`
- one [Party](Party.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.website.WebsiteFormSubmission

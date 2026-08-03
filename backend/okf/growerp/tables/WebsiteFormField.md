---
type: Moqui Entity
title: WebsiteFormField
description: "A single input field of a website lead-capture form."
resource: http://127.0.0.1:8080/rest/e1/growerp.website.WebsiteFormField
tags: [growerp, website]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WebsiteFormField

A single input field of a website lead-capture form.

Full entity name: `growerp.website.WebsiteFormField`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `formId` | id | Y |  |
| `fieldId` | id | Y |  |
| `sequenceNum` | number-integer |  |  |
| `label` | text-medium |  |  |
| `fieldType` | text-short |  |  |
| `isRequired` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [WebsiteForm](WebsiteForm.md) via `formId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.website.WebsiteFormField

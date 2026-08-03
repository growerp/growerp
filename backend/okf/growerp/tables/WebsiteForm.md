---
type: Moqui Entity
title: WebsiteForm
description: "A lead-capture form rendered on the public website; submissions create Lead users."
resource: http://127.0.0.1:8080/rest/e1/growerp.website.WebsiteForm
tags: [growerp, website]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# WebsiteForm

A lead-capture form rendered on the public website; submissions create Lead users.

Full entity name: `growerp.website.WebsiteForm`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `formId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `productStoreId` | id |  |  |
| `formName` | text-medium |  |  |
| `title` | text-medium |  |  |
| `submitLabel` | text-short |  |  |
| `successMessage` | text-medium |  |  |
| `emailSequenceId` | id |  |  |
| `emailTemplateId` | id |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `ownerPartyId`
- one [ProductStore](ProductStore.md) via `productStoreId`
- many [CtaForm LandingPage](LandingPage.md) via `formId`
- many [WebsiteFormField](WebsiteFormField.md) via `formId`
- many [WebsiteFormSubmission](WebsiteFormSubmission.md) via `formId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.website.WebsiteForm

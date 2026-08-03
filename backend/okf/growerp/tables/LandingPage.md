---
type: Moqui Entity
title: LandingPage
description: "Landing Page"
resource: http://127.0.0.1:8080/rest/e1/growerp.landing.LandingPage
tags: [growerp, landing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# LandingPage

Landing Page

Full entity name: `growerp.landing.LandingPage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `landingPageId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `companyPartyId` | id |  |  |
| `title` | text-medium |  |  |
| `hookType` | text-short |  |  |
| `headline` | text-long |  |  |
| `subheading` | text-long |  |  |
| `status` | text-short |  |  |
| `privacyPolicyUrl` | text-long |  |  |
| `ctaActionType` | text-short |  |  |
| `ctaAssessmentId` | id |  |  |
| `ctaButtonLink` | text-long |  |  |
| `ctaFormId` | id |  |  |
| `theme` | text-short |  |  |
| `createdDate` | date-time |  |  |
| `createdByUserLogin` | text-short |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastModifiedByUserLogin` | text-short |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Owner Party](Party.md) via `ownerPartyId`
- one [Company Party](Party.md) via `companyPartyId`
- one [Assessment Assessment](Assessment.md) via `ctaAssessmentId`
- one [CtaForm WebsiteForm](WebsiteForm.md) via `ctaFormId`
- many [LandingPage CredibilityInfo](CredibilityInfo.md) via `landingPageId`
- many [LandingPage PageSection](PageSection.md) via `landingPageId`
- many [MarketingCampaign](MarketingCampaign.md) via `landingPageId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.landing.LandingPage

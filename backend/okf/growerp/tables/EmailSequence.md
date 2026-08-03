---
type: Moqui Entity
title: EmailSequence
description: "A multi-step email drip sequence; leads are enrolled and receive the steps spaced by their delayDays."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.EmailSequence
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmailSequence

A multi-step email drip sequence; leads are enrolled and receive the steps spaced by their delayDays.

Full entity name: `growerp.marketing.EmailSequence`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emailSequenceId` | id | Y |  |
| `pseudoId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `marketingCampaignId` | id |  |  |
| `sequenceName` | text-medium |  |  |
| `status` | text-short |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `ownerPartyId`
- one [MarketingCampaign](MarketingCampaign.md) via `marketingCampaignId`
- many [EmailSequenceEnrollment](EmailSequenceEnrollment.md) via `emailSequenceId`
- many [EmailSequenceStep](EmailSequenceStep.md) via `emailSequenceId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.EmailSequence

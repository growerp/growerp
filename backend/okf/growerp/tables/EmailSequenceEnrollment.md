---
type: Moqui Entity
title: EmailSequenceEnrollment
description: "A lead enrolled in a sequence; currentStep is the last step sent (0 = none yet)."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.EmailSequenceEnrollment
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmailSequenceEnrollment

A lead enrolled in a sequence; currentStep is the last step sent (0 = none yet).

Full entity name: `growerp.marketing.EmailSequenceEnrollment`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `enrollmentId` | id | Y |  |
| `emailSequenceId` | id |  |  |
| `ownerPartyId` | id |  |  |
| `partyId` | id |  |  |
| `emailAddress` | text-medium |  |  |
| `firstName` | text-medium |  |  |
| `currentStep` | number-integer |  |  |
| `status` | text-short |  |  |
| `nextSendDate` | date-time |  |  |
| `opens` | number-integer |  |  |
| `clicks` | number-integer |  |  |
| `unsubscribeToken` | text-short |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmailSequence](EmailSequence.md) via `emailSequenceId`
- one [Party](Party.md) via `partyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.EmailSequenceEnrollment

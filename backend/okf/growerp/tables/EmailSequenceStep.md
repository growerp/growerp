---
type: Moqui Entity
title: EmailSequenceStep
description: "One email in a sequence; delayDays counts from the previous step (or from enrollment for the first step)."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.EmailSequenceStep
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# EmailSequenceStep

One email in a sequence; delayDays counts from the previous step (or from enrollment for the first step).

Full entity name: `growerp.marketing.EmailSequenceStep`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `emailSequenceId` | id | Y |  |
| `stepSeq` | number-integer | Y |  |
| `delayDays` | number-integer |  |  |
| `subject` | text-medium |  |  |
| `bodyHtml` | text-very-long |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [EmailSequence](EmailSequence.md) via `emailSequenceId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.EmailSequenceStep

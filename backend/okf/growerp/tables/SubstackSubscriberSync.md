---
type: Moqui Entity
title: SubstackSubscriberSync
description: "Tracks which email addresses were pushed to Substack as free subscribers; the PK is the dedupe key. FAILED rows are retried on the next sync run."
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.SubstackSubscriberSync
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SubstackSubscriberSync

Tracks which email addresses were pushed to Substack as free subscribers; the PK is the dedupe key. FAILED rows are retried on the next sync run.

Full entity name: `growerp.marketing.SubstackSubscriberSync`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `ownerPartyId` | id | Y |  |
| `emailAddress` | text-medium | Y |  |
| `tenantPartyId` | id |  |  |
| `status` | text-short |  |  |
| `errorMessage` | text-long |  |  |
| `syncedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.SubstackSubscriberSync

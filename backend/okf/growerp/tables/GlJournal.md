---
type: Moqui Entity
title: GlJournal
description: "Gl Journal"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.transaction.GlJournal
tags: [mantle, ledger, transaction]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlJournal

Gl Journal

Full entity name: `mantle.ledger.transaction.GlJournal`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `glJournalId` | id | Y |  |
| `glJournalTypeEnumId` | id |  |  |
| `glJournalName` | text-medium |  |  |
| `organizationPartyId` | id |  |  |
| `isPosted` | text-indicator |  |  |
| `postedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one `moqui.basic.Enumeration` via `glJournalTypeEnumId`
- one [Organization Party](Party.md) via `organizationPartyId`
- many [PartyAcctgPreference](PartyAcctgPreference.md) via `glJournalId`
- many [AcctgTrans](AcctgTrans.md) via `glJournalId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.transaction.GlJournal

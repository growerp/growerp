---
type: Moqui Entity
title: GlAccountTypePartyDefault
description: "Gl Account Type Party Default"
resource: http://127.0.0.1:8080/rest/e1/mantle.ledger.config.GlAccountTypePartyDefault
tags: [mantle, ledger, config]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# GlAccountTypePartyDefault

Gl Account Type Party Default

Full entity name: `mantle.ledger.config.GlAccountTypePartyDefault`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `organizationPartyId` | id | Y |  |
| `partyId` | id | Y |  |
| `roleTypeId` | id | Y |  |
| `glAccountTypeEnumId` | id | Y |  |
| `glAccountId` | id |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Organization Party](Party.md) via `organizationPartyId`
- one [Party](Party.md) via `partyId`
- one [RoleType](RoleType.md) via `roleTypeId`
- one `moqui.basic.Enumeration` via `glAccountTypeEnumId`
- one [GlAccount](GlAccount.md) via `glAccountId`

# Citations

- http://127.0.0.1:8080/rest/e1/mantle.ledger.config.GlAccountTypePartyDefault

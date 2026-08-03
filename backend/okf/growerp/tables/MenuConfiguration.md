---
type: Moqui Entity
title: MenuConfiguration
description: "Menu Configuration"
resource: http://127.0.0.1:8080/rest/e1/growerp.menu.MenuConfiguration
tags: [growerp, menu]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MenuConfiguration

Menu Configuration

Full entity name: `growerp.menu.MenuConfiguration`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `menuConfigurationId` | id | Y |  |
| `ownerPartyId` | id |  | Owner of the menu configuration |
| `appId` | id |  | Application identifier (e.g., 'admin', 'freelance', 'hotel') |
| `userId` | id |  | Optional user-specific override. Null for default app configuration. |
| `name` | text-medium |  |  |
| `description` | text-long |  |  |
| `isActive` | text-indicator |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `ownerPartyId`
- one `moqui.security.UserAccount` via `userId`
- many [MenuItem](MenuItem.md) via `menuConfigurationId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.menu.MenuConfiguration

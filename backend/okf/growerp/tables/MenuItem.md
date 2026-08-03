---
type: Moqui Entity
title: MenuItem
description: "Menu Item"
resource: http://127.0.0.1:8080/rest/e1/growerp.menu.MenuItem
tags: [growerp, menu]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# MenuItem

Menu Item

Full entity name: `growerp.menu.MenuItem`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `menuItemId` | id | Y |  |
| `menuConfigurationId` | id |  | Links to menu configuration (only set for top-level items) |
| `parentMenuItemId` | id |  | Parent menu item for hierarchy (null for top-level items) |
| `itemKey` | id |  | Optional key for identification (e.g., 'dbCompany', 'dbOrders') |
| `title` | text-medium |  |  |
| `route` | text-medium |  | Route path for navigation (e.g., '/companies', '/crm/tasks') |
| `iconName` | text-short |  | Icon identifier from icon registry (e.g., 'home', 'business') |
| `widgetName` | text-medium |  | Widget/Form class name for GoRouter (e.g., 'CompanyList', 'ProductList') |
| `image` | text-medium |  | Path to unselected image |
| `selectedImage` | text-medium |  | Path to selected image |
| `userGroupsJson` | text-long |  | JSON array of user groups with access (e.g., '["Admin","Employee"]') |
| `sequenceNum` | number-integer |  | Display order |
| `isActive` | text-indicator |  |  |
| `isMinimized` | text-indicator |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MenuConfiguration](MenuConfiguration.md) via `menuConfigurationId`
- one [Parent MenuItem](MenuItem.md) via `parentMenuItemId`
- many [Children MenuItem](MenuItem.md) via `menuItemId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.menu.MenuItem

---
type: Moqui Entity
title: PlatformConfiguration
description: "Platform-specific settings and credentials"
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.PlatformConfiguration
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# PlatformConfiguration

Platform-specific settings and credentials

Full entity name: `growerp.marketing.PlatformConfiguration`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `configId` | id | Y |  |
| `ownerPartyId` | id |  |  |
| `platform` | text-short |  | EMAIL, LINKEDIN, TWITTER, MEDIUM, SUBSTACK, FACEBOOK |
| `isEnabled` | text-indicator |  |  |
| `dailyLimit` | number-integer |  |  |
| `apiKey` | text-medium |  | API Key for platform authentication (encrypted) |
| `apiSecret` | text-medium |  | API Secret for platform authentication (encrypted) |
| `username` | text-medium |  | Username for platform authentication (encrypted) |
| `password` | text-medium |  | Password for platform authentication (encrypted) |
| `lastUsedDate` | date-time |  |  |
| `createdDate` | date-time |  |  |
| `lastModifiedDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [Party](Party.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.PlatformConfiguration

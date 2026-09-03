---
type: Moqui Entity
title: SystemSettings
description: "System Settings"
resource: http://127.0.0.1:8080/rest/e1/growerp.general.SystemSettings
tags: [growerp, general]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# SystemSettings

System Settings

Full entity name: `growerp.general.SystemSettings`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `ownerPartyId` | id | Y |  |
| `geminiApiKey` | text-medium |  |  |
| `smtpHost` | text-medium |  |  |
| `smtpPort` | text-short |  |  |
| `smtpStartTls` | text-indicator |  |  |
| `smtpSsl` | text-indicator |  |  |
| `storeHost` | text-medium |  |  |
| `storePort` | text-short |  |  |
| `storeProtocol` | text-short |  |  |
| `storeFolder` | text-medium |  |  |
| `storeDelete` | text-indicator |  |  |
| `storeMarkSeen` | text-indicator |  |  |
| `storeSkipSeen` | text-indicator |  |  |
| `mailUsername` | text-medium |  |  |
| `mailPassword` | text-medium |  |  |
| `githubToken` | text-medium |  |  |
| `githubRepository` | text-medium |  |  |
| `llmSystemTokenLimit` | number-integer |  |  |
| `aiModelName` | text-short |  | Tenant-wide default Gemini model for AI content generation (e.g. gemini-3.7-flash); empty uses the system default. |
| `googleClientId` | text-medium |  |  |
| `googleClientSecret` | text-medium |  |  |
| `googleRefreshToken` | text-medium |  |  |
| `googleCalendarId` | text-medium |  | Google Calendar id to sync bookings from; 'primary' when empty |
| `touristTaxPerNight` | currency-amount |  | Hotel: lodging/tourist tax charged per room per night; 0/empty = none |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- many [LlmConfig](LlmConfig.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.general.SystemSettings

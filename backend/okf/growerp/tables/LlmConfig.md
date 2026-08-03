---
type: Moqui Entity
title: LlmConfig
description: "Llm Config"
resource: http://127.0.0.1:8080/rest/e1/growerp.general.LlmConfig
tags: [growerp, general]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# LlmConfig

Llm Config

Full entity name: `growerp.general.LlmConfig`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `ownerPartyId` | id | Y |  |
| `llmProvider` | text-short | Y |  |
| `apiKey` | text-medium |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [SystemSettings](SystemSettings.md) via `ownerPartyId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.general.LlmConfig

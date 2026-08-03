---
type: Moqui Entity
title: OutreachMessage
description: "Individual outreach message sent via any platform"
resource: http://127.0.0.1:8080/rest/e1/growerp.marketing.OutreachMessage
tags: [growerp, marketing]
timestamp: 2026-07-21T09:59:23.368667987Z
---

# OutreachMessage

Individual outreach message sent via any platform

Full entity name: `growerp.marketing.OutreachMessage`

# Schema

| Column | Type | PK | Description |
|--------|------|----|-------------|
| `messageId` | id | Y |  |
| `marketingCampaignId` | id |  |  |
| `platform` | text-short |  | EMAIL, LINKEDIN, TWITTER, MEDIUM, SUBSTACK, FACEBOOK |
| `recipientName` | text-medium |  |  |
| `recipientProfileUrl` | text-long |  |  |
| `recipientHandle` | text-medium |  | Platform-specific handle (e.g., @username for Twitter) |
| `recipientEmail` | text-medium |  |  |
| `recipientCompany` | text-medium |  |  |
| `recipientTitle` | text-medium |  |  |
| `messageContent` | text-very-long |  |  |
| `sentDate` | date-time |  |  |
| `responseDate` | date-time |  |  |
| `status` | text-short |  | PENDING, SENT, RESPONDED, FAILED |
| `errorMessage` | text-long |  |  |
| `createdDate` | date-time |  |  |
| `lastUpdatedStamp` | date-time |  |  |

# Relationships

- one [MarketingCampaign](MarketingCampaign.md) via `marketingCampaignId`

# Citations

- http://127.0.0.1:8080/rest/e1/growerp.marketing.OutreachMessage

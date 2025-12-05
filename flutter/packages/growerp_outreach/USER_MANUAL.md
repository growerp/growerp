# GrowERP Outreach Package - User Manual

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Features Overview](#features-overview)
4. [Outreach Campaigns](#outreach-campaigns)
5. [Outreach Messages](#outreach-messages)
6. [Platform Configuration](#platform-configuration)
7. [Automation](#automation)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Introduction

The **GrowERP Outreach Package** is a comprehensive solution for managing multi-platform outreach campaigns. It enables businesses to:

- Create and manage outreach campaigns across multiple platforms (Email, LinkedIn, Twitter, Medium, Substack, Facebook)
- Track outreach messages and their responses
- Configure platform-specific settings and daily limits
- Automate outreach workflows
- Monitor campaign performance with real-time metrics

### Key Benefits
- **Multi-Platform Support**: Reach your audience on their preferred platforms
- **Campaign Management**: Organize messages into campaigns for better tracking
- **Automation Ready**: Built-in support for automated outreach workflows
- **Performance Tracking**: Real-time metrics for messages sent, responses, and leads generated
- **Flexible Configuration**: Customize settings per platform

---

## Getting Started

### Prerequisites
- GrowERP backend (Moqui) running
- Flutter application with `growerp_outreach` package installed
- User account with appropriate permissions

### Initial Setup

1. **Access the Outreach Module**
   - Navigate to the main menu
   - Select "Outreach" or "Campaigns" from the navigation

2. **Configure Platforms** (First-time setup)
   - Go to "Platforms" from the menu
   - Configure each platform you plan to use
   - Set daily limits and API credentials

3. **Create Your First Campaign**
   - Click the "+" button on the Campaigns screen
   - Fill in campaign details
   - Start adding messages

---

## Features Overview

### Main Components

1. **Campaigns**: Organize your outreach efforts into campaigns
2. **Messages**: Individual outreach messages sent to recipients
3. **Platform Configuration**: Settings for each social/communication platform
4. **Automation**: Automated workflows for sending messages
5. **Metrics**: Performance tracking and analytics

### Navigation Structure
```
Main Dashboard
├── Campaigns
│   ├── Campaign List
│   └── Campaign Details
├── Messages
│   ├── Message List
│   └── Message Details
├── Automation
│   └── Workflow Management
└── Platforms
    ├── Platform List
    └── Platform Configuration
```

---

## Outreach Campaigns

### Creating a Campaign

1. **Navigate to Campaigns**
   - Click "Campaigns" from the main menu
   - Click the "+" (Add) button

2. **Fill in Campaign Details**
   - **Name** (Required): A descriptive name for your campaign
   - **Campaign ID (PseudoId)** (Optional): A unique identifier for URLs
   - **Platforms** (Required): Select target platforms (comma-separated)
     - Example: `EMAIL,LINKEDIN,TWITTER`
   - **Target Audience** (Optional): Description of your target audience
   - **Message Template** (Optional): Template for messages in this campaign
   - **Email Subject** (Optional): Subject line for email messages
   - **Landing Page** (Optional): Link to a landing page
   - **Daily Limit per Platform** (Optional): Maximum messages per day per platform
     - Default: 50

3. **Save the Campaign**
   - Click "Create" to save
   - The campaign will be created with status "DRAFT"

### Campaign Statuses

- **DRAFT**: Campaign is being prepared
- **ACTIVE**: Campaign is running
- **PAUSED**: Campaign is temporarily stopped
- **COMPLETED**: Campaign has finished

### Viewing Campaign Details

1. Click on any campaign in the list
2. View comprehensive information:
   - Campaign details
   - Associated messages
   - Performance metrics
   - Recent activity

### Campaign Metrics

Each campaign displays:
- **Messages Sent**: Total messages sent
- **Messages Pending**: Messages waiting to be sent
- **Messages Failed**: Messages that failed to send
- **Responses Received**: Number of responses
- **Leads Generated**: Leads created from responses
- **Response Rate**: Percentage of messages that received responses
- **Conversion Rate**: Percentage of messages that generated leads

### Updating a Campaign

1. Open the campaign details
2. Modify any field (except Campaign ID for existing campaigns)
3. Click "Update" to save changes

### Deleting a Campaign

1. In the campaign list, click the delete icon (trash can)
2. Confirm the deletion
3. **Note**: This will also delete all associated messages and metrics

---

## Outreach Messages

### Understanding Messages

Messages are individual outreach communications sent to recipients. They can be:
- Associated with a campaign (recommended)
- Standalone messages (campaign ID optional)

### Creating a Message

#### Desktop Layout
1. **Navigate to Messages**
   - Click "Messages" from the main menu
   - Click the "+" (Add) button

2. **Fill in Message Details** (Single Row)
   - **Campaign ID (PseudoId)** (Optional): Link to a campaign
   - **Status**: Select message status (PENDING, SENT, RESPONDED, FAILED)
   - **Platform**: Choose the platform (EMAIL, LINKEDIN, TWITTER, etc.)

3. **Recipient Information**
   - **Recipient Name** (Optional): Name of the recipient
   - **Recipient Email** (Optional): Email address
   - **Recipient Handle** (Optional): Social media handle (e.g., @username)
   - **Recipient Profile URL** (Optional): Link to recipient's profile

4. **Message Content** (Required)
   - Enter the message text
   - Can be plain text or formatted (depending on platform)

5. **Save the Message**
   - Click "Create" to save
   - Message will be created with the selected status

#### Mobile Layout
- Campaign ID appears on its own line
- Platform and Status appear in a single row
- All other fields follow the same pattern

### Message Statuses

- **PENDING**: Message is queued but not sent
- **SENT**: Message has been sent successfully
- **RESPONDED**: Recipient has responded
- **FAILED**: Message failed to send

### Viewing Messages

#### Message List
The message list displays:
- **Recipient**: Name or email of the recipient
- **Platform**: Which platform the message was sent on
- **Message**: Preview of message content
- **Sent Date**: When the message was sent
- **Status**: Current status with color coding:
  - 🟢 Green: SENT
  - 🔵 Blue: RESPONDED
  - 🔴 Red: FAILED
  - 🟠 Orange: PENDING

#### Message Details
Click on any message to view:
- Full message content
- All recipient information
- Sent date and time
- Response date (if applicable)
- Error message (if failed)

### Updating Message Status

1. Open the message details
2. Change the **Status** dropdown
3. Click "Update Status"
4. The system will:
   - Update the message status
   - Record response date (if status changed to RESPONDED)
   - Update campaign metrics (if associated with a campaign)

### Deleting a Message

1. In the message list, click the delete icon
2. Confirm the deletion
3. The message will be permanently removed

### Searching Messages

1. Click the search icon (magnifying glass)
2. Enter search terms:
   - Recipient name
   - Email address
   - Message content
   - Platform
3. Results appear instantly
4. Click on any result to view details

---

## Platform Configuration

### Supported Platforms

1. **EMAIL**: Email outreach
2. **LINKEDIN**: LinkedIn messages and InMail
3. **TWITTER**: Twitter/X direct messages
4. **MEDIUM**: Medium platform
5. **SUBSTACK**: Substack newsletters
6. **FACEBOOK**: Facebook messages

### Configuring a Platform

1. **Navigate to Platforms**
   - Click "Platforms" from the main menu
   - Click "+" to add a new platform or select existing

2. **Platform Settings**
   - **Platform** (Required): Select the platform
   - **Enabled**: Toggle to enable/disable
   - **Daily Limit** (Required): Maximum messages per day
     - Default: 50
     - Recommended: Start low and increase gradually
   - **API Key** (Optional): Platform API key
   - **API Secret** (Optional): Platform API secret
   - **Username** (Optional): Platform username
   - **Password** (Optional): Platform password

3. **Save Configuration**
   - Click "Create" or "Update"
   - Configuration is saved per company/tenant

### Platform-Specific Notes

#### Email
- Requires SMTP configuration in backend
- Daily limit helps prevent spam flags
- Recommended limit: 50-100 per day

#### LinkedIn
- Requires LinkedIn API credentials
- Strict daily limits (20-50 recommended)
- Respect LinkedIn's terms of service

#### Twitter/X
- Requires Twitter API access
- Daily limits enforced by Twitter
- Recommended: 20-30 per day

#### Medium, Substack, Facebook
- Configuration varies by platform
- Check platform-specific API documentation
- Set conservative daily limits initially

### Viewing Platform Status

The platform list shows:
- Platform name
- Enabled/Disabled status
- Current daily limit
- API configuration status

---

## Automation

### Campaign Automation

The automation feature allows you to:
- Schedule message sending
- Automate follow-ups
- Manage daily sending limits
- Track automation progress

### Starting Automation

1. **Open Campaign Details**
   - Navigate to the campaign you want to automate

2. **Start Automation**
   - Click "Start Automation" button
   - System will:
     - Check platform configurations
     - Verify daily limits
     - Begin sending pending messages

3. **Monitor Progress**
   - View real-time metrics
   - Check messages sent vs. pending
   - Monitor for failures

### Pausing Automation

1. Open the campaign
2. Click "Pause Automation"
3. Automation stops immediately
4. Resume anytime by clicking "Start Automation"

### Automation Rules

- **Daily Limits**: Respects platform daily limits
- **Platform Status**: Only sends on enabled platforms
- **Message Status**: Only sends PENDING messages
- **Error Handling**: Failed messages are marked and logged

---

## Best Practices

### Campaign Management

1. **Start Small**
   - Begin with a small test campaign
   - Verify message templates
   - Test on a few recipients first

2. **Use Clear Naming**
   - Name campaigns descriptively
   - Include date or target audience in name
   - Example: "Q1_2024_Tech_Leads_LinkedIn"

3. **Set Realistic Limits**
   - Don't exceed platform recommendations
   - Start with lower daily limits
   - Increase gradually based on results

4. **Track Performance**
   - Monitor response rates
   - Adjust message templates based on feedback
   - A/B test different approaches

### Message Best Practices

1. **Personalization**
   - Always include recipient name when available
   - Reference specific details about the recipient
   - Avoid generic templates

2. **Clear Call-to-Action**
   - Make it clear what you want the recipient to do
   - Keep messages concise
   - Include relevant links

3. **Timing**
   - Consider time zones
   - Avoid weekends for business outreach
   - Test different sending times

4. **Follow-Up Strategy**
   - Plan follow-up messages
   - Don't be too aggressive
   - Respect "no response" as an answer

### Platform-Specific Tips

#### Email
- Use professional email addresses
- Include unsubscribe option
- Avoid spam trigger words
- Test emails before sending

#### LinkedIn
- Connect before messaging (when possible)
- Keep messages professional
- Reference mutual connections
- Respect InMail limits

#### Twitter/X
- Keep messages under 280 characters
- Use appropriate hashtags
- Engage with content before DMing
- Be conversational

### Data Management

1. **Regular Cleanup**
   - Archive completed campaigns
   - Remove failed messages after review
   - Export data periodically

2. **Privacy Compliance**
   - Respect GDPR/privacy laws
   - Maintain opt-out lists
   - Secure recipient data

3. **Backup Strategy**
   - Export campaign data regularly
   - Keep records of successful campaigns
   - Document what works

---

## Troubleshooting

### Common Issues

#### Messages Not Sending

**Problem**: Messages remain in PENDING status

**Solutions**:
1. Check platform configuration is enabled
2. Verify API credentials are correct
3. Check daily limit hasn't been reached
4. Review error logs in message details
5. Ensure automation is started

#### Campaign Metrics Not Updating

**Problem**: Metrics show zero despite sent messages

**Solutions**:
1. Ensure messages are linked to campaign (campaignId set)
2. Check message status is SENT (not PENDING)
3. Refresh the campaign details page
4. Verify backend services are running

#### Platform Configuration Issues

**Problem**: Cannot save platform configuration

**Solutions**:
1. Verify all required fields are filled
2. Check API credentials format
3. Ensure daily limit is a positive number
4. Check backend connectivity

#### Search Not Working

**Problem**: Search returns no results

**Solutions**:
1. Check search term spelling
2. Try broader search terms
3. Verify messages exist in the system
4. Clear search and try again

### Error Messages

#### "Method post not supported"
- **Cause**: Backend REST API not configured
- **Solution**: Ensure Moqui server is running with latest configuration

#### "Campaign not found"
- **Cause**: Invalid campaign ID
- **Solution**: Verify campaign exists and ID is correct

#### "Platform not configured"
- **Cause**: Platform settings missing
- **Solution**: Configure platform in Platform Configuration screen

#### "Daily limit reached"
- **Cause**: Platform daily limit exceeded
- **Solution**: Wait until next day or increase limit in platform config

### Getting Help

1. **Check Logs**
   - Backend: Moqui server logs
   - Frontend: Browser console

2. **Verify Configuration**
   - Platform settings
   - Campaign settings
   - Message details

3. **Test Connectivity**
   - Backend API accessible
   - Database connection active
   - Platform APIs responding

4. **Contact Support**
   - Visit: https://www.growerp.com
   - Email: support@growerp.com
   - Documentation: https://docs.growerp.com

---

## Appendix

### Keyboard Shortcuts

- **Search**: Click search icon or use platform-specific shortcuts
- **Add New**: Click "+" button
- **Refresh**: Pull down on mobile, F5 on desktop

### Data Export

Messages and campaigns can be exported through:
1. GrowERP's general export functionality
2. Backend database queries
3. REST API endpoints

### API Reference

For developers integrating with the Outreach package:

**Endpoints**:
- `GET /rest/s1/growerp/100/OutreachCampaigns` - List campaigns
- `POST /rest/s1/growerp/100/OutreachCampaign` - Create campaign
- `PATCH /rest/s1/growerp/100/OutreachCampaign` - Update campaign
- `DELETE /rest/s1/growerp/100/OutreachCampaign` - Delete campaign
- `GET /rest/s1/growerp/100/OutreachMessage` - List messages
- `POST /rest/s1/growerp/100/OutreachMessage` - Create message
- `PATCH /rest/s1/growerp/100/OutreachMessage` - Update message status
- `DELETE /rest/s1/growerp/100/OutreachMessage` - Delete message

### Version History

**Version 1.0.0** (Current)
- Initial release
- Campaign management
- Message CRUD operations
- Platform configuration
- Basic automation
- Performance metrics

---

## Glossary

- **Campaign**: A collection of related outreach messages
- **Message**: Individual communication sent to a recipient
- **Platform**: Communication channel (Email, LinkedIn, etc.)
- **Daily Limit**: Maximum messages allowed per day per platform
- **Response Rate**: Percentage of messages that received responses
- **Conversion Rate**: Percentage of messages that generated leads
- **Automation**: Automated message sending workflow
- **PseudoId**: Human-readable unique identifier for campaigns
- **Metrics**: Performance statistics for campaigns and messages

---

## Quick Reference Card

### Campaign Quick Actions
| Action | Steps |
|--------|-------|
| Create Campaign | Menu → Campaigns → + → Fill form → Create |
| View Metrics | Menu → Campaigns → Click campaign |
| Start Automation | Campaign Details → Start Automation |
| Delete Campaign | Campaign List → Delete icon → Confirm |

### Message Quick Actions
| Action | Steps |
|--------|-------|
| Create Message | Menu → Messages → + → Fill form → Create |
| Update Status | Message Details → Change status → Update |
| Search Messages | Messages → Search icon → Enter term |
| Delete Message | Message List → Delete icon → Confirm |

### Platform Quick Actions
| Action | Steps |
|--------|-------|
| Configure Platform | Menu → Platforms → + → Fill form → Create |
| Enable/Disable | Platform Details → Toggle enabled → Update |
| Update Limits | Platform Details → Change limit → Update |

---

**Document Version**: 1.0  
**Last Updated**: December 5, 2024  
**Package Version**: growerp_outreach 1.0.0  

For the latest documentation, visit: https://www.growerp.com/docs

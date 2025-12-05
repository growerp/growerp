# What Happens When You Start a Campaign - Technical Explanation

## Overview

When you click "Start Automation" on a campaign, the system initiates an automated workflow that searches for prospects, sends personalized messages, and tracks results. This document explains the complete process step-by-step.

---

## The Complete Workflow

### Phase 1: Campaign Activation (Backend)

**Service Called**: `start#CampaignAutomation`

**What Happens**:

1. **Validation**
   - System verifies the campaign exists
   - Checks that you own the campaign (ownerPartyId matches)
   - Returns error if campaign not found

2. **Status Update**
   - Campaign status changes from `DRAFT` → `ACTIVE`
   - `lastModifiedDate` is updated to current timestamp
   - `lastModifiedByUserLogin` records who started it

3. **Response**
   - Returns success message: "Campaign automation started"
   - Campaign status is now `ACTIVE`

**Code Location**: `/moqui/runtime/component/growerp/service/growerp/100/OutreachServices100.xml` (lines 920-953)

---

### Phase 2: Automation Orchestration (Frontend)

**Component**: `AutomationOrchestrator`

**What Happens**:

1. **Initialization**
   ```
   - Reads campaign platforms (e.g., "EMAIL,LINKEDIN,TWITTER")
   - Creates platform-specific adapters for each platform
   - Initializes each adapter (sets up browser automation, API connections, etc.)
   ```

2. **Platform Adapter Creation**
   - **EMAIL**: `EmailAutomationAdapter` - Uses SMTP/email services
   - **LINKEDIN**: `LinkedInAutomationAdapter` - Uses browser automation (Puppeteer)
   - **TWITTER**: `XAutomationAdapter` - Uses browser automation (Puppeteer)
   - Other platforms can be added similarly

**Code Location**: `/flutter/packages/growerp_outreach/lib/src/services/automation_orchestrator.dart`

---

### Phase 3: Message Sending Loop

For **each platform** in the campaign:

#### Step 1: Login Check
```
- Adapter checks if logged into the platform
- If not logged in → throws error
- User must be authenticated to the platform first
```

#### Step 2: Profile Search
```
- Uses campaign's targetAudience or searchCriteria
- Searches for profiles matching criteria
- Returns list of potential recipients (ProfileData objects)
```

**ProfileData includes**:
- `name`: Recipient's name
- `email`: Email address (if available)
- `handle`: Social media handle (e.g., @username)
- `profileUrl`: Link to their profile
- `company`: Company name (if available)
- `title`: Job title (if available)

#### Step 3: Message Personalization & Sending

For **each profile** found (up to daily limit):

1. **Check Cancellation**
   - User can cancel automation at any time
   - Loop breaks if cancelled

2. **Check Daily Limit**
   - Stops if daily limit reached for this platform
   - Respects platform configuration settings

3. **Personalize Message**
   - Takes campaign's `messageTemplate`
   - Replaces placeholders:
     - `{name}` → Recipient's name
     - `{company}` → Recipient's company
     - `{title}` → Recipient's job title
   - Example: "Hi {name}, I noticed you work at {company}..." becomes
     "Hi John Smith, I noticed you work at Acme Corp..."

4. **Send Message**
   - **EMAIL**: Sends direct email via SMTP
   - **LINKEDIN**: Sends connection request with note
   - **TWITTER**: Sends direct message (if allowed)
   - Platform adapter handles the actual sending

5. **Record Success in Database**
   - Creates `OutreachMessage` record with:
     - `campaignId`: Links to this campaign
     - `platform`: Which platform was used
     - `recipientName`, `recipientEmail`, `recipientHandle`, `recipientProfileUrl`
     - `messageContent`: The personalized message sent
     - `status`: `SENT`
     - `sentDate`: Current timestamp

6. **Update Campaign Metrics**
   - Increments `messagesSent` counter
   - Updates campaign's `CampaignMetrics` table

7. **Human-Like Delay**
   - Adds random delay between messages to avoid spam detection:
     - **EMAIL**: 30-60 seconds
     - **LINKEDIN**: 2-5 minutes
     - **TWITTER**: 3-7 minutes
   - Makes automation appear more natural

#### Step 4: Error Handling

If message sending fails:

1. **Log Error**
   - Prints error to console
   - Continues to next recipient (doesn't stop entire campaign)

2. **Record Failure**
   - Creates `OutreachMessage` record with:
     - `status`: `FAILED`
     - `errorMessage`: Error details
   - Increments `messagesFailed` counter

3. **Continue**
   - Moves to next profile
   - Doesn't count against daily limit

---

### Phase 4: Progress Tracking

**Throughout the automation**, you can check progress:

**Service**: `get#CampaignProgress`

**Returns**:
- `campaignId`: The campaign ID
- `status`: Current status (ACTIVE, PAUSED, etc.)
- `messagesSent`: Total messages successfully sent
- `messagesPending`: Messages waiting to be sent
- `messagesFailed`: Messages that failed
- `responsesReceived`: Number of responses
- `leadsGenerated`: Leads created from responses

**Real-time Updates**:
- Campaign detail screen shows live metrics
- Metrics update after each message is sent
- You can see progress without refreshing

---

## Platform-Specific Details

### EMAIL Platform

**How it works**:
1. Uses backend SMTP configuration
2. Sends emails directly via email server
3. No browser automation needed
4. Fastest platform (30-60 second delays)

**Requirements**:
- SMTP server configured in Moqui backend
- Valid email credentials
- Recipient email addresses

### LINKEDIN Platform

**How it works**:
1. Uses browser automation (Puppeteer via MCP server)
2. Opens LinkedIn in headless browser
3. Searches for profiles matching criteria
4. Sends connection requests with personalized notes
5. Tracks sent requests

**Requirements**:
- LinkedIn account credentials in platform config
- MCP HTTP Bridge running (`npm start` in outreach package)
- Puppeteer MCP server running
- Valid LinkedIn session

**Limitations**:
- LinkedIn limits connection requests (20-50 per day recommended)
- Must respect LinkedIn's terms of service
- Longer delays (2-5 minutes) to avoid detection

### TWITTER/X Platform

**How it works**:
1. Uses browser automation (Puppeteer via MCP server)
2. Opens Twitter/X in headless browser
3. Searches for users matching criteria
4. Sends direct messages (if DMs are open)
5. Tracks sent messages

**Requirements**:
- Twitter/X account credentials
- MCP HTTP Bridge running
- Puppeteer MCP server running
- Recipients must allow DMs

**Limitations**:
- Twitter limits DMs
- Can only DM users who follow you or have open DMs
- Longer delays (3-7 minutes) recommended

---

## Pausing a Campaign

**Service Called**: `pause#CampaignAutomation`

**What Happens**:
1. Campaign status changes from `ACTIVE` → `PAUSED`
2. Automation loop checks for pause status
3. Current message completes, then stops
4. No new messages are sent
5. Progress is saved
6. Can be resumed anytime

---

## Important Notes

### Daily Limits

**Purpose**: Prevent spam detection and account bans

**How it works**:
- Each platform has a `dailyLimit` setting
- Campaign also has `dailyLimitPerPlatform` setting
- System uses the lower of the two
- Resets at midnight (UTC)

**Recommendations**:
- **EMAIL**: 50-100 per day
- **LINKEDIN**: 20-50 per day
- **TWITTER**: 20-30 per day

### Message Status Flow

```
PENDING → SENT → RESPONDED
         ↓
       FAILED
```

- **PENDING**: Message queued but not sent yet
- **SENT**: Successfully sent to recipient
- **RESPONDED**: Recipient replied
- **FAILED**: Failed to send (error occurred)

### Metrics Updates

**When metrics update**:
- After each message is sent
- When status changes to RESPONDED
- When leads are generated
- Real-time in the UI

**What gets tracked**:
- `messagesSent`: Total sent successfully
- `messagesPending`: Waiting in queue
- `messagesFailed`: Failed to send
- `responsesReceived`: Replies received
- `leadsGenerated`: Leads created
- `responseRate`: (responses / sent) × 100
- `conversionRate`: (leads / sent) × 100

---

## Technical Architecture

### Components Involved

1. **Frontend (Flutter)**
   - Campaign detail screen
   - Automation orchestrator
   - Platform adapters
   - BLoC for state management

2. **Backend (Moqui)**
   - Campaign services
   - Message services
   - Metrics tracking
   - REST API endpoints

3. **Browser Automation (Optional)**
   - MCP HTTP Bridge (Node.js)
   - Puppeteer MCP server
   - Headless browser instances

4. **Database**
   - OutreachCampaign table
   - OutreachMessage table
   - CampaignMetrics table
   - PlatformConfiguration table

### Data Flow

```
User clicks "Start Automation"
    ↓
Frontend calls REST API: POST /rest/s1/growerp/100/OutreachCampaign/start
    ↓
Backend updates campaign status to ACTIVE
    ↓
Frontend AutomationOrchestrator initializes
    ↓
For each platform:
    ↓
    Initialize platform adapter
    ↓
    Check login status
    ↓
    Search for profiles
    ↓
    For each profile (up to daily limit):
        ↓
        Personalize message
        ↓
        Send message via platform
        ↓
        Record in database (POST /rest/s1/growerp/100/OutreachMessage)
        ↓
        Update metrics
        ↓
        Wait (human-like delay)
    ↓
Automation complete or paused
```

---

## Example Scenario

**Campaign Setup**:
- Name: "Q1 2024 Tech Leads"
- Platforms: "EMAIL,LINKEDIN"
- Target Audience: "Software Engineers at startups"
- Message Template: "Hi {name}, I noticed you work at {company} as a {title}. I'd love to connect!"
- Daily Limit: 50 per platform

**When Started**:

1. **Initialization** (2 seconds)
   - Email adapter initialized
   - LinkedIn adapter initialized
   - Both adapters check login status

2. **Email Platform** (25 minutes)
   - Searches for 50 software engineers
   - Sends 50 personalized emails
   - 30-60 second delay between each
   - Creates 50 OutreachMessage records (status: SENT)
   - Updates metrics: messagesSent = 50

3. **LinkedIn Platform** (2-4 hours)
   - Searches for 50 software engineers
   - Sends 50 connection requests
   - 2-5 minute delay between each
   - Creates 50 OutreachMessage records (status: SENT)
   - Updates metrics: messagesSent = 100

4. **Completion**
   - Total messages sent: 100
   - Campaign status remains: ACTIVE
   - Ready for next day's automation

---

## Monitoring & Control

### Real-Time Monitoring

**Campaign Detail Screen shows**:
- Current status (ACTIVE/PAUSED)
- Messages sent today
- Messages pending
- Messages failed
- Response rate
- Recent messages list

### Control Options

**While Running**:
- ✅ Pause automation
- ✅ View progress
- ✅ Check individual messages
- ✅ Monitor metrics
- ❌ Cannot edit campaign settings (pause first)

**When Paused**:
- ✅ Resume automation
- ✅ Edit campaign settings
- ✅ Review sent messages
- ✅ Add more messages manually

---

## Best Practices

1. **Start Small**
   - Test with 5-10 messages first
   - Verify messages are being sent correctly
   - Check personalization works

2. **Monitor Closely**
   - Watch first few messages in real-time
   - Check for errors
   - Verify platform logins stay active

3. **Respect Limits**
   - Don't exceed platform recommendations
   - Start with lower daily limits
   - Increase gradually based on results

4. **Review Regularly**
   - Check failed messages
   - Adjust message templates based on responses
   - Update target criteria if needed

5. **Pause When Needed**
   - Pause if error rate is high
   - Pause to review and adjust
   - Pause overnight if needed

---

## Troubleshooting

### Automation Not Starting

**Check**:
- Campaign status is ACTIVE
- Platform configurations are enabled
- Daily limits not already reached
- Platform logins are valid

### Messages Not Sending

**Check**:
- Platform adapter initialized successfully
- Login credentials are correct
- Search criteria returns profiles
- Daily limit not reached
- No errors in console logs

### High Failure Rate

**Possible Causes**:
- Invalid recipient data
- Platform API errors
- Network connectivity issues
- Rate limiting by platform
- Invalid credentials

**Solutions**:
- Pause automation
- Review failed messages
- Check platform configuration
- Reduce daily limit
- Verify credentials

---

## Summary

**Starting a campaign triggers**:
1. Status change to ACTIVE
2. Platform adapter initialization
3. Profile search for each platform
4. Automated message sending with:
   - Personalization
   - Human-like delays
   - Error handling
   - Progress tracking
5. Real-time metrics updates
6. Continuous monitoring until:
   - Daily limit reached
   - Campaign paused
   - All messages sent
   - Error occurs

**The result**: Automated, personalized outreach at scale while maintaining a human-like sending pattern and respecting platform limits.

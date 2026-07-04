# Comprehensive Marketing & Sales Actions (Weeks 2-4)

This document outlines the granular, day-to-day operational breakdown for the engineering and marketing teams over the remaining 3 weeks of the sprint.

## Week 2: Auto-Opportunity Creation on Reply

*The goal this week is backend automation: seamlessly moving a prospect from the marketing module to the sales CRM without human intervention.*

### Engineering / Backend (Moqui & ADK)
*   **Action 1 (ECA Trigger):** Write an Entity Condition Action (ECA) in Moqui that listens for state changes on outreach messages. When a message's status changes to `RESPONDED`, trigger the `create#SalesOpportunity` service.
*   **Action 2 (Data Mapping):** Map the prospect's `PartyId`, Company, and Contact info from the outreach record to the new `SalesOpportunity`. Automatically set the initial opportunity stage to "Warm Lead."
*   **Action 3 (Attribution):** Ensure the `CampaignId` is linked to the `SalesOpportunity` so you can track which specific AI prompt or outreach channel generated the lead.
*   **Action 4 (Notification Routing):** Configure the Lead Triage Agent to send a chat ping to the assigned human SDR with a direct deep-link to the newly created opportunity in the CRM.

### Marketing / Ops
*   **Action 5:** Prepare the second batch of CSV leads (e.g., 1,000 new LinkedIn profiles) and run the `import#OutreachRecipients` tool.
*   **Action 6:** Review the Daily Ops Digest from Week 1. Identify which AI subject lines had the highest open rates and adjust the `MasterContent` prompts for Week 2 accordingly.

---

## Week 3: Inbound Reply Detection (Webhooks & Real-Time Polling)

*The goal this week is speed-to-lead: intercepting prospect replies instantly to capitalize on their attention.*

### Engineering / Backend (Moqui & ADK)
*   **Action 1 (Inbound Webhooks):** Set up an inbound parse webhook with your email provider (e.g., SendGrid/AWS SES) to route incoming emails directly to a new Moqui REST endpoint (`/rest/s1/growerp/inboundWebhook`).
*   **Action 2 (Polling Jobs):** For platforms that don't support webhooks (like LinkedIn), create a high-frequency background job (`poll_social_replies`) that runs every 5 minutes to fetch new inbox messages.
*   **Action 3 (Triage Acceleration):** Update the Lead Triage Agent. Instead of running on a 30-minute cron schedule, have it trigger *immediately* upon the webhook payload arriving.
*   **Action 4 (Frontend Sockets):** Ensure the Flutter frontend (`growerp_sales`) listens to WebSocket events so the human SDR's screen flashes/updates instantly when the Triage Agent flags a hot reply.

### Marketing / Ops
*   **Action 5:** QA the real-time flow by sending test replies to the outbound campaign and measuring how many seconds it takes for the Triage Agent to draft a response.
*   **Action 6:** Launch the Week 3 "News" themed content via the Content Studio Agent across all 6 channels.

---

## Week 4: Productization & "Business in a Box" Template

*The goal this week is to package the entire sprint's technical setup into a deployable product feature for your actual customers.*

### Engineering / Backend (Moqui & ADK)
*   **Action 1 (Configuration Bundling):** Extract the successful AI Prompts (SDR, Personalizer, Triage), Campaign Schedules, and Event Logic into a consolidated Moqui seed data file (e.g., `SdrTemplateSeedData.xml`).
*   **Action 2 (Tenant Deployment Script):** Create a service that allows a new GrowERP tenant to initialize these records safely within their own isolated tenant environment.
*   **Action 3 (Frontend Setup Wizard):** In the Flutter `growerp_marketing` app, build a UI for a "1-Click AI Sales Machine" setup. This should include a simple wizard for the user to define their own ICP and upload their own CSV of leads.

### Marketing / Ops
*   **Action 4:** Create a 2-minute demo video showing how GrowERP just successfully ran its own marketing motion entirely internally.
*   **Action 5:** Update the `ERP_LANDING_PAGE` to feature the new "Reusable Sales SDR Template" as the core hook.
*   **Action 6:** Sprint Retrospective. Pull the final `CampaignMetrics` to analyze Total Sent vs. Total Replies vs. Closed-Won Deals, and document the ROI to use in future marketing materials.

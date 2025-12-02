# Social Media Lead Activation and Nurturing System Design

## Overview
This document outlines the technical design for the **Social Media Lead Activation and Nurturing System** within GrowERP. The system is designed to automate and streamline the process of finding, engaging, and converting leads using AI-driven content, strategic outreach, and interactive landing pages.

The system is divided into four distinct phases:
1.  **Targeted Content Creation (AI-Driven)**
2.  **Lead Acquisition & Signal Detection**
3.  **Initial Outreach (Cold DMs)**
4.  **Lead Warming & Conversion (Scorecard/Landing Page)**

## Architecture

```mermaid
graph TD
    subgraph "Phase 1: Content Creation (AI)"
        Avatar[Customer Avatar Generator] -->|Defines| Persona[Marketing Persona]
        Persona -->|Feeds| PNP[PNP Engine]
        PNP -->|Generates| Plan[Content Plan]
        Plan -->|Drafts| Draft[Content Drafting Module]
        Draft -->|Humanize| Post[Social Post]
    end

    subgraph "Phase 2: Acquisition"
        Post -->|Published to| Social[Social Media (LinkedIn/etc)]
        Social -->|Engagement| Signals[Engagement Monitor]
        Squad[PLC Squadron] -->|Boosts| Social
    end

    subgraph "Phase 3: Outreach"
        Signals -->|Triggers| ColdDM[Cold DM Sender]
        Repo[Template Repository] -->|Provides Script| ColdDM
        ColdDM -->|Sends| DM[Direct Message]
    end

    subgraph "Phase 4: Conversion"
        DM -->|Links to| LP[Landing Page]
        LP -->|Hosts| Scorecard[Scorecard / Assessment]
        Scorecard -->|Qualifies| Lead[Warm Lead]
        Lead -->|Books| Appt[Appointment Booking]
    end
```

## Component Breakdown

### Phase 1: Targeted Content Creation and Curation (AI-Driven)

This phase leverages Generative AI to assist users in creating high-quality, targeted content.

#### Data Models (New Entities)
*   **`MarketingPersona`**: Stores the "Customer Avatar" details (psychographics, pain points, goals).
    *   Fields: `personaId`, `name`, `demographics`, `painPoints`, `goals`, `toneOfVoice`.
*   **`ContentPlan`**: Represents the weekly "Pain-News-Prize" schedule.
    *   Fields: `planId`, `weekStartDate`, `theme`.
*   **`SocialPost`**: Represents a specific piece of content.
    *   Fields: `postId`, `planId`, `type` (Pain/News/Prize), `headline`, `draftContent`, `finalContent`, `status` (Draft/Scheduled/Published).

#### Services
*   **`generatePersona`**: AI service to generate persona details based on basic business info.
*   **`generateContentPlan`**: AI service to generate 10 headlines (PNP formula) based on a Persona.
*   **`draftPost`**: AI service to generate full post text from a headline.

#### UI Components
*   **Persona Editor**: Form to view/edit the AI-generated avatar.
*   **Content Calendar**: View of the weekly plan with drag-and-drop drafting.

---

### Phase 2: Lead Acquisition and Signal Detection

Focuses on tracking engagement to identify potential leads.

#### Data Models
*   **`SocialEngagement`**: Records interactions.
    *   Fields: `engagementId`, `postId`, `platform`, `userProfileUrl`, `type` (Like/Comment/Share), `status` (New/Contacted).
*   **`PlcSquadron`**: Manages the support group.
    *   Fields: `squadronId`, `members` (List of PartyIds).

#### Services
*   **`recordEngagement`**: Service to manually (or via webhook) log a "Signal of Interest".
*   **`notifySquadron`**: Notification service to alert the PLC group of a new post.

---

### Phase 3: Initial Outreach (Cold DMs)

Manages the direct messaging workflow.

#### Data Models
*   **`OutreachTemplate`**: Stores DM scripts.
    *   Fields: `templateId`, `name`, `content`, `variables` (e.g., {{Name}}).
*   **`OutreachCampaign`**: Groups outreach efforts.
    *   Fields: `campaignId`, `postId`, `targetCount` (e.g., 10).
*   **`OutreachMessage`**: A specific message sent to a lead.
    *   Fields: `messageId`, `campaignId`, `leadProfileUrl`, `sentDate`, `status` (Sent/Replied).

#### Services
*   **`generateDmDraft`**: AI service to customize a template for a specific lead profile.
*   **`logDmSent`**: Records that a DM was sent.

---

### Phase 4: Lead Warming and Conversion

Leverages existing GrowERP capabilities with extensions for Booking.

#### Existing Components
*   **`LandingPage`**: Used to host the content and Scorecard.
    *   *Ref*: `LandingPageServices100.xml`
*   **`Assessment` (Scorecard)**: The interactive quiz to qualify leads.
    *   *Ref*: `AssessmentServices100.xml`
    *   *Enhancement*: Ensure "Lead Status" (Cold/Warm/Hot) logic is fully configurable (already present in `ScoringThreshold`).

#### New Components (Booking)
*   **`AppointmentSlot`**: Available times for consultation.
    *   Fields: `slotId`, `startDateTime`, `endDateTime`, `status` (Available/Booked).
*   **`Appointment`**: A booked meeting.
    *   Fields: `appointmentId`, `slotId`, `leadPartyId`, `notes`.
*   **Note**: Future integration with Google Calendar API for appointment scheduling.

#### Services
*   **`getAvailableSlots`**: Returns open slots.
*   **`bookAppointment`**: Reserves a slot for a lead (potentially auto-created from Assessment submission).

## Integration Strategy

1.  **Backend (Moqui)**:
    *   Create a new component `growerp_marketing` within the existing GrowERP component structure.
    *   Implement the Entities and Services defined above.
    *   Integrate with an LLM provider (e.g., Gemini/OpenAI) for the AI services.

2.  **Frontend (Flutter)**:
    *   Add a "Marketing" main menu item.
    *   Sub-screens: "Personas", "Content Calendar", "Lead Signals", "Outreach".
    *   Integrate `LandingPage` and `Assessment` screens into this flow.

3.  **External Integrations**:
    *   **LinkedIn/Socials**: Initially manual (copy-paste). Future: API integration for auto-posting and listening.
    *   **Calendar**: Initially internal `AppointmentSlot`. Future: Google Calendar/Calendly integration.

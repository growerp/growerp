# Outreach Package Documentation

This document describes the `growerp_outreach` package, covering its internal operation and the workflow from a user's perspective.

## Internal Operation

The Outreach package is designed to manage and automate marketing campaigns across multiple platforms (Email, LinkedIn, Twitter, etc.). It follows a clean architecture pattern with separation of concerns between the UI, State Management (BLoC), Services, and the Backend.

### Architecture Overview

1.  **Frontend (Flutter)**:
    *   **BLoC (`OutreachCampaignBloc`)**: Manages the state of campaigns. It handles events for fetching, creating, updating, and deleting campaigns. It communicates with the backend via `RestClient`.
    *   **Services**:
        *   **`AutomationOrchestrator`**: The core service responsible for executing campaigns. It manages platform-specific adapters and coordinates the automation workflow (login, search, message sending).
        *   **Adapters (`PlatformAutomationAdapter`)**: Abstract base class for platform-specific implementations.
            *   **`EmailAutomationAdapter`**: Implemented using `RestClient` to send emails via the backend.
            *   **`LinkedInAutomationAdapter`**: (In Progress) Intended to use `BrowserMcpService` for browser-based automation.
            *   **`TwitterAutomationAdapter`**: (In Progress) Intended to use `BrowserMcpService`.
        *   **`BrowserMcpService`**: A service to interface with the Model Context Protocol (MCP) for controlling a browser, enabling automation of web-based platforms.

2.  **Backend (Moqui)**:
    *   **Entities (`OutreachEntities.xml`)**:
        *   `OutreachCampaign`: Stores campaign details (name, platforms, message template, etc.).
        *   `OutreachMessage`: Tracks individual messages sent, their status, and recipient details.
        *   `CampaignMetrics`: Aggregates performance data (messages sent, responses, leads).
        *   `PlatformConfiguration`: Stores credentials and settings for each platform.
    *   **Services (`OutreachServices100.xml`)**:
        *   CRUD services for Campaigns (`create#OutreachCampaign`, `update#OutreachCampaign`, etc.).
        *   `send#OutreachEmail`: Handles sending emails via Moqui's `EmailServices`, including unsubscribe links and tracking.
        *   Metrics calculation and updates.

### Data Model

*   **Campaign**: The central entity. It defines *what* to send (Message Template), *who* to send it to (Target Audience/Search Criteria), and *where* (Platforms).
*   **PseudoId**: A user-friendly ID (e.g., `10001`) used for identifying campaigns in the UI and URLs.
*   **Status**: Campaigns move through states like `DRAFT`, `ACTIVE`, `PAUSED`, `COMPLETED`.

### Automation Logic

The `AutomationOrchestrator` follows this logic:
1.  **Initialize**: Sets up adapters for selected platforms.
2.  **Run**: For each platform:
    *   Checks login status.
    *   Searches for profiles matching the criteria.
    *   Iterates through profiles:
        *   Personalizes the message template.
        *   Sends the message (or connection request).
        *   Updates metrics.
        *   Waits for a random delay to mimic human behavior.

## User Workflow

This section describes how a user interacts with the Outreach package to create and manage campaigns.

### 1. Accessing Campaigns
*   Navigate to the **Marketing** section in the main menu.
*   Select **Outreach Campaigns**.
*   The **Campaign List Screen** displays all existing campaigns with their status and key metrics.

### 2. Creating a Campaign
*   Click the **"New" (+)** button.
*   **Campaign Details**:
    *   **Name**: Enter a descriptive name for the campaign.
    *   **Status**: Set initial status (usually `DRAFT`).
    *   **Target Audience**: Describe the target audience (used for search criteria).
    *   **Message Template**: Write the message to be sent. Use placeholders like `{name}`, `{company}` for personalization.
    *   **Email Subject**: (If Email platform is selected) Enter the email subject line.
    *   **Daily Limit**: Set the maximum number of messages to send per day per platform.
*   **Platforms**: Select the platforms to target (e.g., Email, LinkedIn).
*   Click **Create**.

### 3. Managing Campaigns
*   **View Details**: Tap on a campaign in the list to view its full details and performance metrics.
*   **Update**: Edit campaign fields (e.g., refine the message template or change the daily limit) and save changes.
*   **Delete**: (If available) Remove a campaign.

### 4. Running Automation (Conceptual)
*   Once a campaign is `ACTIVE`, the system (via a background job or manual trigger) initiates the `AutomationOrchestrator`.
*   The system will:
    *   Log in to the configured platforms.
    *   Find new leads matching the "Target Audience".
    *   Send personalized messages up to the "Daily Limit".
    *   Track sent messages and update campaign metrics.

### 5. Monitoring Results
*   Users can monitor the **Campaign Metrics** (Messages Sent, Responses, Leads Generated) directly from the Campaign List or Detail screen to evaluate the effectiveness of their outreach.

# GrowERP Outreach Example

Example application demonstrating the `growerp_outreach` package for multi-platform outreach campaign management.

## Features

- **Campaign Management**: Create and manage outreach campaigns across multiple platforms
- **Multi-Platform Support**: Email, LinkedIn, Twitter, Medium, Substack, and Facebook
- **Campaign Metrics**: Track messages sent, responses, and leads generated
- **Message History**: View all messages sent as part of campaigns
- **Platform Adapters**: Extensible architecture for adding new platforms
- **Browser Automation**: MCP-based browser automation for LinkedIn/Twitter (via Playwright)

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- GrowERP backend running locally or accessible via network
- Melos for workspace management
- Node.js (for browser automation features)

### Running the Example

1. **Bootstrap the workspace** (from flutter directory):
   ```bash
   melos bootstrap
   ```

2. **Run the example app**:
   ```bash
   cd packages/growerp_outreach/example
   flutter run
   ```

3. **Login** with your GrowERP credentials

## Browser Automation (BrowserMCP Test)

The example includes a **Browser Test** screen for testing MCP-based browser automation using Playwright.

### Prerequisites for Browser Automation

Install the Playwright MCP server globally:

```bash
npm install -g @playwright/mcp
```

### Running on Linux (Native)

On Linux (and probably Windows, MacOs), the browser automation works out of the box:

1. Run the example app:
   ```bash
   flutter run -d linux
   ```

2. Navigate to **Browser Test** from the menu

3. Click **Initialize** to start the Playwright MCP server (spawned automatically)

4. Enter a URL and click **Navigate**

5. Click **Get Snapshot** to capture the page's accessibility tree

6. Click **View Snapshot** to see the full element tree

The native implementation automatically spawns the `mcp-server-playwright` process and communicates via STDIO.

### Running on Chrome (Web)

On web platforms, browsers cannot spawn processes directly. You need to run the Playwright MCP server externally with a CORS proxy.

#### Step 1: Start the Playwright MCP Server

```bash
mcp-server-playwright --port 9222 --headless
```

#### Step 2: Start the CORS Proxy

The Playwright MCP server doesn't support CORS, so a proxy is required for web browsers:

```bash
cd flutter/packages/growerp_outreach
node mcp_cors_proxy.js
```

This starts a proxy on port 9223 that forwards to the MCP server on port 9222.

#### Step 3: Run the Flutter Web App

```bash
cd flutter/packages/growerp_outreach/example
flutter run -d chrome
```

#### Step 4: Use the Browser Test Screen

1. Navigate to **Browser Test** from the menu
2. Click **Initialize** (connects to `http://localhost:9223/mcp`)
3. Enter a URL and click **Navigate**
4. Click **Get Snapshot** to capture the page's accessibility tree
5. Click **View Snapshot** to see the full element tree

### Architecture

The browser automation uses conditional imports for platform-specific implementations:

- **Native (Linux/Windows/macOS)**: Uses `StdioClientTransport` to spawn and communicate with `mcp-server-playwright` via STDIO
- **Web (Chrome/Edge/Firefox)**: Uses `StreamableHttpClientTransport` to connect to an externally running MCP server via HTTP/SSE

### Snapshot Format

The Playwright MCP server returns an accessibility tree in YAML format:

```yaml
- generic [ref=e2]:
  - heading "Example Domain" [level=1] [ref=e3]
  - paragraph [ref=e4]: This domain is for use in documentation...
  - paragraph [ref=e5]:
    - link "Learn more" [ref=e6] [cursor=pointer]
```

Each element has:
- **role**: The accessibility role (heading, link, button, etc.)
- **name**: The accessible name (text content or label)
- **ref**: A reference ID for interacting with the element
- **attributes**: Additional properties like `[level=1]` or `[cursor=pointer]`

## Menu Structure

The example app includes the following menu options:

- **Main**: Dashboard with quick access to campaigns
- **Outreach**: 
  - Campaigns: List and manage all outreach campaigns
  - Automation: Platform automation controls (coming soon)
  - Leads: View and manage leads generated from campaigns
- **Browser Test**: Test browser automation with Playwright MCP
- **Organization**: Company and employee management

## Using the Outreach Features

### Creating a Campaign

1. Navigate to **Outreach → Campaigns**
2. Click the **+** button to create a new campaign
3. Fill in campaign details:
   - Campaign name
   - Select platforms (Email, LinkedIn, Twitter, etc.)
   - Target audience description
   - Message template with personalization tokens
   - Email subject (if EMAIL platform selected)
   - Daily limit per platform
4. Save the campaign

### Viewing Campaign Metrics

1. Click on any campaign in the list
2. View metrics dashboard showing:
   - Messages sent
   - Responses received
   - Leads generated
   - Response rate
3. Scroll down to see message history

### Platform Adapters

The example demonstrates the platform adapter architecture:

- **Email**: Uses Moqui EmailServices for sending
- **LinkedIn**: Uses Playwright MCP for browser automation
- **Twitter**: Uses Playwright MCP for browser automation

## Integration with Backend

The example connects to the GrowERP backend services:

- `OutreachCampaign` entity for campaign data
- `OutreachMessage` entity for message tracking
- `CampaignMetrics` entity for performance metrics
- `PlatformConfiguration` entity for platform settings

## Development

To extend this example:

1. Add new screens to `lib/`
2. Update `menu_options.dart` to include new menu items
3. Implement platform adapters in the main `growerp_outreach` package
4. Add integration tests in `integration_test/`

## License

This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License.

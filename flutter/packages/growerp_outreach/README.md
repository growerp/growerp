# GrowERP Outreach Package

A Flutter package for multi-platform marketing outreach and campaign automation within the GrowERP ecosystem.

## Features

- **Campaign Management**: Create, manage, and track outreach campaigns
- **Multi-Platform Support**: Email, LinkedIn, Twitter/X automation
- **Lead Targeting**: Define and manage target audiences for campaigns
- **Template System**: Reusable message templates with variable substitution
- **Rate Limiting**: Platform-specific rate limiting to avoid API throttling
- **MCP Browser Automation**: Puppeteer-based browser automation via MCP protocol

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  growerp_outreach:
    path: ../growerp_outreach  # or git reference
```

## Dependencies

This package requires:
- `growerp_core` - Core functionality and utilities
- `growerp_models` - Data models and API client
- `mcp_dart` - MCP protocol support for browser automation

## Quick Start

### 1. Add BLoC Providers

```dart
import 'package:growerp_outreach/growerp_outreach.dart';

// In your app setup
MultiBlocProvider(
  providers: [
    ...getOutreachBlocProviders(restClient, 'AppAdmin'),
  ],
  child: MyApp(),
)
```

### 2. Use Campaign List Screen

```dart
import 'package:growerp_outreach/growerp_outreach.dart';

// Navigate to campaigns
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const CampaignListScreen()),
);
```

### 3. Automation Setup (Linux)

For browser automation on Linux:

```dart
import 'package:growerp_outreach/growerp_outreach.dart';

// Create MCP browser service with Linux paths
final config = McpServerConfig.linux();
final browserService = FlutterMcpBrowserService();
await browserService.initialize(config: config);
```

## Architecture

```
lib/
├── src/
│   ├── bloc/           # BLoC state management
│   ├── screens/        # UI screens
│   ├── services/       # Automation services
│   │   ├── adapters/   # Platform-specific adapters
│   │   └── mcp/        # MCP browser integration
│   ├── utils/          # Utilities (rate limiter, etc.)
│   └── widgets/        # Reusable widgets
└── growerp_outreach.dart  # Public exports
```

## Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Email | ✅ Ready | Uses Moqui backend SMTP |
| LinkedIn | ✅ Ready | Browser automation via MCP |
| Twitter/X | ✅ Ready | Browser automation via MCP |
| Substack | ✅ Ready | Browser automation via MCP (subscribe, notes, comments) |
| Facebook | 🚧 Planned | Not yet implemented |

## Rate Limits

Default platform rate limits (configurable):

| Platform | Requests/Hour |
|----------|---------------|
| Email | 500 |
| LinkedIn | 100 |
| Twitter | 50 |

## Testing

Run unit tests:

```bash
cd flutter/packages/growerp_outreach
flutter test
```

Run integration tests:

```bash
cd flutter/packages/growerp_outreach/example
flutter test integration_test/
```

## Running Automated Outreach

### Option 1: Interactive Testing via Example App

```bash
cd flutter/packages/growerp_outreach/example
flutter run -d linux
```

Navigate to:
- **Campaigns** - Create, manage, and execute campaigns
- **LinkedIn Messaging** - Send messages to 1st-level connections
- **Automation** - View active campaigns and status

### Option 2: Campaign Execution Dialog

From the Campaign list, click the **Execute (▶)** button on any campaign row to open the Campaign Execution Dialog. This dialog provides platform-specific tabs based on the campaign's configured platforms:

**LinkedIn Tab:**
- Message 1st-Level Connections
- Search & Send Connection Requests
- Fetch connections, select recipients, compose message

**Twitter/X Tab:**
- Post Tweet
- Search & Follow Profiles
- Send Direct Messages

**Substack Tab:**
- Post Note
- Search & Subscribe to Publications
- Comment on Latest Posts

**Email Tab:**
- Send emails via Moqui backend
- Uses campaign's email subject and message template

### Option 3: LinkedIn Messaging Workflow

1. **Start the app** and go to "LinkedIn Messaging"
2. **Click "Start Browser"** - Opens Chromium via Playwright
3. **Login to LinkedIn** manually in the browser window
4. **Click "Fetch Connections"** - Retrieves your 1st-level connections
5. **Select contacts** and compose your message
6. **Send** - Messages are sent with rate limiting (10-20 second delays)

### Option 4: Programmatic Automation

```dart
import 'package:growerp_outreach/growerp_outreach.dart';

Future<void> runOutreachCampaign() async {
  final restClient = RestClient(await buildDioClient());
  final orchestrator = AutomationOrchestrator(restClient);
  
  // Initialize platform adapters
  await orchestrator.initialize(['LINKEDIN']);
  
  // Define target leads (or let it search)
  final leads = [
    ProfileData(name: 'John Doe', profileUrl: 'https://linkedin.com/in/johndoe'),
  ];
  
  // Run automation with rate limiting
  await orchestrator.runAutomation(
    platform: 'LINKEDIN',
    searchCriteria: 'flutter developer',  // Used if no targetLeads
    messageTemplate: 'Hi {name}, I wanted to connect about {company}!',
    dailyLimit: 10,
    campaignId: 'campaign-123',
    targetLeads: leads,
    checkCancelled: () => false,
  );
  
  // Check stats
  print(orchestrator.getRateLimiterStats('LINKEDIN'));
  
  await orchestrator.cleanup();
}
```

### Option 4: Direct LinkedIn Adapter

```dart
import 'package:growerp_outreach/growerp_outreach.dart';

Future<void> sendLinkedInMessages() async {
  final linkedin = LinkedInAutomationAdapter();
  await linkedin.initialize();
  
  // User must login manually first
  if (!await linkedin.isLoggedIn()) {
    print('Please login to LinkedIn in the browser');
    return;
  }
  
  // Get 1st-level connections
  final connections = await linkedin.getFirstLevelConnections(
    maxResults: 20,
    scrollCount: 2,
  );
  
  // Send personalized messages with rate limiting
  final results = await linkedin.sendBatchMessages(
    connections: connections,
    messageTemplate: '''
Hi {name},

I wanted to reach out about our new product. Would love to connect!

Best regards
''',
    delayBetweenMessages: Duration(seconds: 15),
  );
  
  // Check results
  for (final result in results) {
    if (result.success) {
      print('✓ Sent to ${result.profile.name}');
    } else {
      print('✗ Failed: ${result.profile.name} - ${result.error}');
    }
  }
  
  await linkedin.cleanup();
}
```

### Prerequisites for Browser Automation

1. **Install Node.js** (via nvm recommended):
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
   nvm install 24
   ```

2. **Install Playwright MCP**:
   ```bash
   npm install -g @anthropic-ai/mcp-server-playwright
   ```

3. **Set environment variables** (optional, auto-detected if using nvm):
   ```bash
   export MCP_NODE_PATH=$HOME/.nvm/versions/node/v24.11.1/bin/node
   export MCP_PLAYWRIGHT_PATH=$HOME/.nvm/versions/node/v24.11.1/lib/node_modules/@playwright/mcp/cli.js
   ```

4. **Login manually** - The browser opens, you must login to LinkedIn/Twitter before automation runs

### Rate Limiting

The system enforces platform-specific rate limits to avoid detection:

| Platform | Actions/Hour | Notes |
|----------|-------------|-------|
| Email | 60 | 1 per minute |
| LinkedIn | 20 | Conservative to stay under radar |
| Twitter | 15 | Twitter is strict about automation |

Additional random jitter (0-10 seconds) is added between actions to appear more human.

## Configuration

### MCP Browser Service

The MCP browser service requires Node.js and the Playwright MCP server:

```bash
# Install Node.js via nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
nvm install 24
nvm use 24

# Install Playwright MCP globally
npm install -g @anthropic/mcp-server-puppeteer
```

Configure paths via factory methods:

```dart
// Auto-detect from environment (nvm setup)
final config = McpServerConfig.fromEnvironment();

// Linux-specific paths with nvm
final config = McpServerConfig.linux(
  homeDir: '/home/myuser',
  nodeVersion: 'v24.11.1',
);

// Custom explicit paths
final config = McpServerConfig(
  nodePath: '/path/to/node',
  playwrightMcpPath: '/path/to/@playwright/mcp/cli.js',
  homeDir: '/home/myuser',
  pathEnv: '/usr/bin:/bin',
);
```

## Contributing

See the main [GrowERP CONTRIBUTING.md](../../../CONTRIBUTING.md) for guidelines.

## License

This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License.

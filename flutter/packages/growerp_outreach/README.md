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

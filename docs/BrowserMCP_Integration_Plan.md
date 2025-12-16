# BrowserMCP Integration Plan for GrowERP Outreach

This document outlines the architecture and implementation plan for integrating browsermcp (Model Context Protocol browser automation) with GrowERP's outreach automation system.

## Overview

The GrowERP outreach module uses browsermcp to automate social media interactions on platforms like LinkedIn and Twitter/X. The integration leverages the MCP protocol to control a browser instance for profile searches, connection requests, and direct messaging.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Frontend                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │              AutomationOrchestrator                          ││
│  │  - Coordinates automation across platforms                   ││
│  │  - Manages campaign execution                                ││
│  └───────────────────────┬─────────────────────────────────────┘│
│                          │                                       │
│  ┌───────────────────────┴─────────────────────────────────────┐│
│  │              PlatformAutomationAdapter (Interface)           ││
│  └───────────────────────┬─────────────────────────────────────┘│
│                          │                                       │
│  ┌───────────┬───────────┼───────────┬───────────────────────┐  │
│  │           │           │           │                        │  │
│  ▼           ▼           ▼           ▼                        │  │
│ Email    LinkedIn      X/Twitter    (Future)                  │  │
│ Adapter   Adapter      Adapter      Adapters                  │  │
│  │           │           │                                    │  │
│  │     ┌─────┴───────────┴─────────────────────────────────┐  │  │
│  │     │           BrowserMCPService                        │  │  │
│  │     │  - High-level browser automation                   │  │  │
│  │     │  - Snapshot parsing                                │  │  │
│  │     │  - Element interaction                             │  │  │
│  │     └───────────────────────┬───────────────────────────┘  │  │
│  │                             │                               │  │
│  │     ┌───────────────────────┴───────────────────────────┐  │  │
│  │     │              MCPBridge (HTTP Client)               │  │  │
│  │     │  - Communicates with MCP HTTP Bridge               │  │  │
│  │     │  - Tool invocation: navigate, click, type, etc.    │  │  │
│  │     └───────────────────────┬───────────────────────────┘  │  │
│  │                             │                               │  │
└──┼─────────────────────────────┼───────────────────────────────┘  │
   │                             │                                   │
   ▼                             ▼                                   │
Moqui Backend              MCP HTTP Bridge                          │
(REST API)                 (localhost:3000)                         │
   │                             │                                   │
   │                             ▼                                   │
   │                      browsermcp Server                          │
   │                      (MCP Protocol)                             │
   │                             │                                   │
   │                             ▼                                   │
   │                      Chromium Browser                           │
   │                      (Playwright)                               │
   │                                                                 │
```

## Components

### 1. MCPBridge (`lib/src/services/mcp_bridge.dart`)

Low-level HTTP client for MCP tool invocation.

```dart
class MCPBridge {
  final String baseUrl; // Default: http://localhost:3000/mcp
  
  Future<Map<String, dynamic>> callTool(String tool, Map<String, dynamic> args);
  Future<void> navigate(String url);
  Future<Map<String, dynamic>> snapshot();
  Future<void> click({String? element, String? ref});
  Future<void> type({required String text, String? element, String? ref});
}
```

### 2. BrowserMCPService (`lib/src/services/browser_mcp_service.dart`)

High-level browser automation with parsing and retry logic.

```dart
class BrowserMCPService {
  Future<void> initialize();
  Future<void> navigate(String url);
  Future<SnapshotElement> snapshot(); // Parsed accessibility tree
  Future<void> click({String? element, String? ref});
  Future<void> type({required String text, String? element, String? ref});
  Future<void> wait(int milliseconds);
  Future<String?> getCurrentUrl();
}
```

### 3. SnapshotParser (`lib/src/services/snapshot_parser.dart`)

Parses browsermcp accessibility tree snapshots.

```dart
class SnapshotElement {
  final String ref;      // Element reference for clicking
  final String role;     // Accessibility role (button, link, textbox, etc.)
  final String? name;    // Accessible name/label
  final String? value;   // Current value
  final Map<String, dynamic> attributes;
  final List<SnapshotElement> children;
}

class SnapshotParser {
  static SnapshotElement? parse(Map<String, dynamic> snapshot);
  static List<SnapshotElement> findAll(SnapshotElement root, {...});
  static SnapshotElement? findFirst(SnapshotElement root, {...});
  static SnapshotElement? findByText(SnapshotElement root, String text);
  static SnapshotElement? findButton(SnapshotElement root, String text);
  static SnapshotElement? findLink(SnapshotElement root, String text);
  static SnapshotElement? findInput(SnapshotElement root, String label);
}
```

### 4. Platform Adapters

#### LinkedInAutomationAdapter

```dart
class LinkedInAutomationAdapter implements PlatformAutomationAdapter {
  Future<void> initialize();        // Navigate to linkedin.com
  Future<bool> isLoggedIn();        // Check for logged-in nav elements
  Future<List<ProfileData>> searchProfiles(String criteria);
  Future<void> sendConnectionRequest(ProfileData profile, String message);
  Future<void> sendDirectMessage(ProfileData profile, String message, {String? campaignId, String? subject});
}
```

#### XAutomationAdapter (Twitter/X)

```dart
class XAutomationAdapter implements PlatformAutomationAdapter {
  Future<void> initialize();        // Navigate to x.com
  Future<bool> isLoggedIn();        // Check for home timeline
  Future<List<ProfileData>> searchProfiles(String criteria);
  Future<void> sendConnectionRequest(ProfileData profile, String message); // Follow
  Future<void> sendDirectMessage(ProfileData profile, String message, {String? campaignId, String? subject});
}
```

## Setup Requirements

### 1. Install browsermcp

```bash
# Via npm
npm install -g @anthropic/mcp-browsermcp

# Or via npx (no install)
npx @anthropic/mcp-browsermcp
```

### 2. Run MCP HTTP Bridge

The Flutter app communicates with browsermcp via an HTTP bridge that translates REST calls to MCP protocol.

```bash
# Option 1: Use mcp-http-bridge
npm install -g mcp-http-bridge
mcp-http-bridge --port 3000 --mcp-command "npx @anthropic/mcp-browsermcp"

# Option 2: Custom bridge (see scripts/mcp_http_bridge.js)
node scripts/mcp_http_bridge.js
```

### 3. Configure GrowERP

Update `app_settings.json` or environment:

```json
{
  "mcpBridgeUrl": "http://localhost:3000/mcp"
}
```

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| MCPBridge | ✅ Complete | HTTP client for MCP tool calls |
| BrowserMCPService | ✅ Complete | High-level browser automation |
| SnapshotParser | ✅ Complete | Accessibility tree parsing |
| ElementSelector | ✅ Complete | Element matching utilities |
| EmailAutomationAdapter | ✅ Complete | Uses Moqui backend directly |
| LinkedInAutomationAdapter | ⚠️ Partial | Structure complete, needs testing |
| XAutomationAdapter | ⚠️ Partial | Structure complete, needs testing |
| MCP HTTP Bridge | ❌ Not Started | Need to create or integrate |

## Usage Example

```dart
// Initialize adapter
final linkedin = LinkedInAutomationAdapter();
await linkedin.initialize();

// Check login status (user must be logged in manually)
if (!await linkedin.isLoggedIn()) {
  throw Exception('Please log in to LinkedIn first');
}

// Search for profiles
final profiles = await linkedin.searchProfiles('Flutter developer');

// Send connection requests with personalized message
for (final profile in profiles) {
  await linkedin.sendConnectionRequest(
    profile,
    'Hi ${profile.name}, I noticed your Flutter experience...',
  );
  await Future.delayed(Duration(seconds: 30)); // Rate limiting
}
```

## MCP Tools Used

### browsermcp_navigate
Navigate to a URL.
```json
{"tool": "browsermcp_navigate", "arguments": {"url": "https://linkedin.com"}}
```

### browsermcp_snapshot
Get accessibility tree of current page.
```json
{"tool": "browsermcp_snapshot", "arguments": {}}
```

### browsermcp_click
Click an element by ref or description.
```json
{"tool": "browsermcp_click", "arguments": {"ref": "abc123"}}
```

### browsermcp_type
Type text into the focused element.
```json
{"tool": "browsermcp_type", "arguments": {"text": "Hello world"}}
```

## Security Considerations

1. **Authentication**: Users must manually log in to platforms. The automation runs in the context of their browser session.

2. **Rate Limiting**: Implement delays between actions to avoid platform detection.

3. **Session Management**: Browser sessions are ephemeral. Consider persisting cookies for longer sessions.

4. **Network Access**: MCP bridge runs locally. For production, consider:
   - Running bridge on same machine as app
   - Using secure tunnel for remote access
   - Implementing authentication on bridge

## Rate Limiting Strategy

To avoid platform restrictions:

| Platform | Action | Recommended Delay |
|----------|--------|-------------------|
| LinkedIn | Profile view | 5-10 seconds |
| LinkedIn | Connection request | 30-60 seconds |
| LinkedIn | Direct message | 15-30 seconds |
| X/Twitter | Profile view | 3-5 seconds |
| X/Twitter | Follow | 10-20 seconds |
| X/Twitter | Direct message | 10-20 seconds |

## Error Handling

```dart
try {
  await adapter.sendConnectionRequest(profile, message);
} on MCPConnectionError catch (e) {
  // MCP bridge not running
  logger.severe('MCP bridge not available: $e');
} on MCPToolError catch (e) {
  // Tool execution failed
  logger.warning('MCP tool error: $e');
} on PlatformRateLimitError catch (e) {
  // Platform detected automation
  logger.warning('Rate limited, pausing: $e');
  await Future.delayed(Duration(minutes: 5));
}
```

## Future Enhancements

1. **Session Persistence**: Save browser cookies between runs
2. **Multi-profile Support**: Run automation for multiple accounts
3. **Headless Mode**: Run browser headlessly for server deployment
4. **Proxy Support**: Route traffic through proxies for rate limit avoidance
5. **AI-Enhanced Targeting**: Use LLM to evaluate profile fit before connecting
6. **Message Personalization**: AI-generated personalized messages based on profile

## Testing

### Unit Tests
```dart
// Test snapshot parsing
test('parses LinkedIn search results', () {
  final snapshot = loadFixture('linkedin_search.json');
  final element = SnapshotParser.parse(snapshot);
  final links = SnapshotParser.findAll(element!, role: 'link');
  expect(links, isNotEmpty);
});
```

### Integration Tests
```dart
// Test with real MCP bridge
testWidgets('searches LinkedIn profiles', (tester) async {
  final adapter = LinkedInAutomationAdapter();
  await adapter.initialize();
  
  // Must be logged in
  expect(await adapter.isLoggedIn(), isTrue);
  
  final profiles = await adapter.searchProfiles('test');
  expect(profiles, isNotEmpty);
});
```

## Monitoring

Track automation metrics in OutreachCampaign:

- `messagesSent`: Total messages sent across all platforms
- `connectionsSent`: Connection/follow requests sent
- `responsesReceived`: Replies received
- `conversionRate`: Leads converted to customers

## Related Files

- `lib/src/services/mcp_bridge.dart` - HTTP bridge client
- `lib/src/services/browser_mcp_service.dart` - High-level browser service
- `lib/src/services/snapshot_parser.dart` - Accessibility tree parser
- `lib/src/services/element_selector.dart` - Element matching utilities
- `lib/src/services/adapters/` - Platform-specific adapters
- `lib/src/automation/automation_orchestrator.dart` - Campaign execution

## References

- [browsermcp GitHub](https://github.com/anthropics/mcp-browsermcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Playwright Documentation](https://playwright.dev/)
- [GrowERP Outreach Module](../flutter/packages/growerp_outreach/)

import 'dart:convert';
import 'package:logging/logging.dart' as logging;
import 'package:mcp_dart/mcp_dart.dart';
import 'snapshot_parser.dart';

// Conditional import for platform-specific implementations
import 'flutter_mcp_browser_service_stub.dart'
    if (dart.library.io) 'flutter_mcp_browser_service_native.dart'
    if (dart.library.js_interop) 'flutter_mcp_browser_service_web.dart';

// Re-export config class for native platforms (stubbed on web)
export 'flutter_mcp_browser_service_stub.dart'
    if (dart.library.io) 'flutter_mcp_browser_service_native.dart'
    if (dart.library.js_interop) 'flutter_mcp_browser_service_web.dart'
    show McpServerConfig;

/// Browser automation service using mcp_dart package
///
/// This service uses the mcp_dart package to communicate with
/// the official Playwright MCP server.
///
/// Platform behavior:
/// - **Native (Linux, Windows, macOS)**: Uses STDIO transport to spawn
///   the Playwright MCP process automatically.
/// - **Web (Chrome, etc.)**: Uses HTTP/SSE transport. Requires the
///   Playwright MCP server to be running externally with:
///   ```bash
///   mcp-server-playwright --port 9222 --headless
///   ```
///
/// Configuration (Native only):
/// The MCP server paths can be configured in several ways:
///
/// 1. Environment variables:
///    - MCP_NODE_PATH: Path to Node.js executable
///    - MCP_PLAYWRIGHT_PATH: Path to Playwright MCP CLI script
///
/// 2. Programmatically before calling initialize():
///    ```dart
///    import 'package:growerp_outreach/growerp_outreach.dart';
///    FlutterMcpBrowserServiceImpl.config = McpServerConfig.linux(
///      homeDir: '/home/myuser',
///      nodeVersion: 'v20.0.0',
///    );
///    ```
///
/// 3. Factory constructors for common setups:
///    - McpServerConfig.fromEnvironment() - Auto-detect from env vars
///    - McpServerConfig.linux() - NVM-based Linux setup
///    - McpServerConfig.system() - System-installed Node.js
class FlutterMcpBrowserService {
  static final logging.Logger _logger =
      logging.Logger('outreach.FlutterMcpBrowserService');

  late final FlutterMcpBrowserServiceImpl _impl;
  SnapshotElement? _lastSnapshot;
  String? _currentUrl;

  FlutterMcpBrowserService() {
    _impl = createBrowserServiceImpl();
  }

  /// Initialize the MCP client and connect to Playwright MCP
  ///
  /// [serverUrl] - For web platform only: URL of the Playwright MCP server
  ///               (e.g., http://localhost:9222/mcp). Ignored on native platforms.
  Future<void> initialize({String? serverUrl}) async {
    if (_impl.isInitialized) {
      _logger.fine('Already initialized');
      return;
    }

    _logger.info('Initializing Playwright MCP via mcp_dart');

    try {
      await _impl.initialize(serverUrl: serverUrl);
      _logger.info('BrowserMCP client initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize browsermcp client', e, stackTrace);
      await _cleanup();
      rethrow;
    }
  }

  /// Navigate to a URL
  Future<void> navigate(String url) async {
    _ensureInitialized();

    _logger.info('Navigating to: $url');

    await _callTool('browser_navigate', {'url': url});
    _currentUrl = url;

    _logger.fine('Navigation complete');
  }

  /// Take a snapshot of the current page
  Future<SnapshotElement> snapshot() async {
    _ensureInitialized();

    _logger.fine('Taking page snapshot');

    final result = await _callTool('browser_snapshot', {});

    // Playwright MCP returns text-based accessibility tree
    final text = result['text'] as String?;
    SnapshotElement? root;

    if (text != null) {
      // Parse Playwright's text format
      root = SnapshotParser.parseText(text);
    } else {
      // Fall back to JSON format (for @browsermcp compatibility)
      root = SnapshotParser.parse(result);
    }

    if (root == null) {
      throw Exception('Failed to parse snapshot');
    }

    _lastSnapshot = root;
    _currentUrl = result['url'] as String?;
    _logger.fine('Snapshot captured: ${root.children.length} children');

    return root;
  }

  /// Click an element on the page
  Future<void> click({
    required String element,
    required String ref,
  }) async {
    _ensureInitialized();

    _logger.info('Clicking: $element');

    await _callTool('browser_click', {
      'element': element,
      'ref': ref,
    });

    _logger.fine('Click complete');
  }

  /// Click element by SnapshotElement
  Future<void> clickElement(SnapshotElement element) async {
    await click(
      element: element.name ?? element.role,
      ref: element.ref,
    );
  }

  /// Type text into an input field
  Future<void> type({
    required String element,
    required String ref,
    required String text,
    bool submit = false,
  }) async {
    _ensureInitialized();

    _logger.info('Typing into $element');

    await _callTool('browser_type', {
      'element': element,
      'ref': ref,
      'text': text,
      'submit': submit,
    });

    _logger.fine('Typing complete');
  }

  /// Type into element by SnapshotElement
  Future<void> typeIntoElement(
    SnapshotElement element,
    String text, {
    bool submit = false,
  }) async {
    await type(
      element: element.name ?? element.role,
      ref: element.ref,
      text: text,
      submit: submit,
    );
  }

  /// Wait for a specified duration (in milliseconds)
  Future<void> wait(int milliseconds) async {
    _ensureInitialized();

    _logger.fine('Waiting ${milliseconds}ms');

    await _callTool('browser_wait', {
      'time': milliseconds / 1000.0, // browsermcp uses seconds
    });
  }

  /// Take a screenshot
  Future<String?> screenshot() async {
    _ensureInitialized();

    _logger.fine('Taking screenshot');

    final result = await _callTool('browser_screenshot', {});
    return result['screenshot'] as String?;
  }

  /// Go back to previous page
  Future<void> goBack() async {
    _ensureInitialized();

    _logger.info('Going back');

    await _callTool('browser_go_back', {});
  }

  /// Go forward to next page
  Future<void> goForward() async {
    _ensureInitialized();

    _logger.info('Going forward');

    await _callTool('browser_go_forward', {});
  }

  /// Hover over an element
  Future<void> hover({
    required String element,
    required String ref,
  }) async {
    _ensureInitialized();

    _logger.fine('Hovering over: $element');

    await _callTool('browser_hover', {
      'element': element,
      'ref': ref,
    });
  }

  /// Press a key
  Future<void> pressKey(String key) async {
    _ensureInitialized();

    _logger.fine('Pressing key: $key');

    await _callTool('browser_press_key', {'key': key});
  }

  /// Scroll the page by executing JavaScript
  ///
  /// [direction] - 'down', 'up', 'bottom', 'top'
  /// [pixels] - Number of pixels to scroll (for 'down'/'up')
  Future<void> scroll({
    String direction = 'down',
    int pixels = 500,
  }) async {
    _ensureInitialized();

    _logger.fine('Scrolling $direction');

    // Use Page Down/Up keys for scrolling (more reliable than JS)
    switch (direction) {
      case 'down':
        await pressKey('PageDown');
        break;
      case 'up':
        await pressKey('PageUp');
        break;
      case 'bottom':
        await pressKey('End');
        break;
      case 'top':
        await pressKey('Home');
        break;
    }
  }

  /// Evaluate JavaScript on the page (if supported by MCP server)
  ///
  /// Note: This may not be supported by all MCP server implementations.
  /// Falls back to using keyboard shortcuts for common operations.
  Future<Map<String, dynamic>> evaluate(String script) async {
    _ensureInitialized();

    _logger.fine('Evaluating script');

    try {
      // Try browser_evaluate tool (may not exist in all MCP servers)
      return await _callTool('browser_evaluate', {'script': script});
    } catch (e) {
      _logger.warning('browser_evaluate not supported, using fallback');

      // For common scroll operations, use keyboard fallback
      if (script.contains('scrollTo') && script.contains('scrollHeight')) {
        await pressKey('End');
        return {'success': true, 'fallback': true};
      }

      rethrow;
    }
  }

  /// Get console logs
  Future<List<String>> getConsoleLogs() async {
    _ensureInitialized();

    final result = await _callTool('browser_get_console_logs', {});
    return (result['logs'] as List?)?.cast<String>() ?? [];
  }

  /// Get current URL
  String? get currentUrl => _currentUrl;

  /// Get last snapshot
  SnapshotElement? get lastSnapshot => _lastSnapshot;

  /// Check if initialized
  bool get isInitialized => _impl.isInitialized;

  /// Cleanup and close browser session
  Future<void> cleanup() async {
    await _cleanup();
  }

  Future<void> _cleanup() async {
    _logger.info('Cleaning up browser session');

    await _impl.cleanup();

    _currentUrl = null;
    _lastSnapshot = null;

    _logger.info('Browser session closed');
  }

  /// Call an MCP tool
  Future<Map<String, dynamic>> _callTool(
    String tool,
    Map<String, dynamic> params,
  ) async {
    final client = _impl.client;
    if (client == null) {
      throw StateError('Client not initialized');
    }

    _logger.fine('Calling MCP tool: $tool');

    try {
      final result = await client.callTool(
        CallToolRequestParams(name: tool, arguments: params),
      );

      // Parse the result content
      if (result.content.isNotEmpty) {
        final content = result.content.first;
        if (content is TextContent) {
          // Try to parse as JSON
          try {
            final decoded = jsonDecode(content.text);
            if (decoded is Map) {
              return Map<String, dynamic>.from(decoded);
            }
            return {'text': content.text};
          } catch (_) {
            return {'text': content.text};
          }
        }
      }
      return {};
    } catch (e, stackTrace) {
      _logger.severe('MCP tool call failed: $tool', e, stackTrace);
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_impl.isInitialized) {
      throw StateError(
          'FlutterMcpBrowserService not initialized. Call initialize() first.');
    }
  }
}

import 'package:logging/logging.dart' as logging;
import 'package:mcp_dart/mcp_dart.dart';

/// Stub configuration - web platform uses serverUrl parameter instead
class McpServerConfig {
  const McpServerConfig._();
}

/// Web implementation using HTTP/SSE transport
///
/// On web, we cannot spawn processes, so the Playwright MCP server
/// must be running externally with --port flag for SSE transport.
///
/// Start the server manually before using:
/// ```bash
/// mcp-server-playwright --port 9222 --headless
/// ```
class FlutterMcpBrowserServiceImpl {
  static final logging.Logger _logger =
      logging.Logger('outreach.FlutterMcpBrowserServiceImpl.web');

  Client? _client;
  StreamableHttpClientTransport? _transport;
  bool _isInitialized = false;

  /// Default URL for the Playwright MCP server via CORS proxy
  ///
  /// The Playwright MCP server doesn't support CORS, so we need a proxy.
  /// Start both:
  /// 1. mcp-server-playwright --port 9222 --headless
  /// 2. node mcp_cors_proxy.js (runs on port 9223)
  static const String defaultServerUrl = 'http://localhost:9223/mcp';

  bool get isInitialized => _isInitialized;
  Client? get client => _client;
  Transport? get transport => _transport;

  /// Initialize the MCP client using HTTP transport
  ///
  /// [serverUrl] - URL of the Playwright MCP CORS proxy (e.g., http://localhost:9223/mcp)
  ///               Start the proxy with: node mcp_cors_proxy.js
  Future<void> initialize({String? serverUrl}) async {
    if (_isInitialized) {
      _logger.fine('Already initialized');
      return;
    }

    final url = serverUrl ?? defaultServerUrl;
    _logger.info('Initializing Playwright MCP via HTTP transport: $url');

    // Create HTTP/SSE transport for web
    // The Playwright MCP server must be running with --port flag
    _transport = StreamableHttpClientTransport(
      Uri.parse(url),
    );

    // Create and connect the MCP client
    _client = Client(
      const Implementation(
          name: 'GrowERP Browser Client (Web)', version: '1.0.0'),
    );

    await _client!.connect(_transport!);
    _isInitialized = true;
    _logger.info('BrowserMCP client initialized successfully via HTTP');
  }

  Future<void> cleanup() async {
    _logger.info('Cleaning up browser session');

    try {
      await _client?.close();
    } catch (e) {
      _logger.warning('Error closing client: $e');
    }

    try {
      await _transport?.close();
    } catch (e) {
      _logger.warning('Error closing transport: $e');
    }

    _client = null;
    _transport = null;
    _isInitialized = false;

    _logger.info('Browser session closed');
  }
}

/// Factory function for creating the web implementation
FlutterMcpBrowserServiceImpl createBrowserServiceImpl() {
  return FlutterMcpBrowserServiceImpl();
}

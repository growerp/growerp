import 'dart:io' as io;
import 'package:logging/logging.dart' as logging;
import 'package:mcp_dart/mcp_dart.dart';

/// Native (non-web) implementation using STDIO transport
class FlutterMcpBrowserServiceImpl {
  static final logging.Logger _logger =
      logging.Logger('outreach.FlutterMcpBrowserServiceImpl.native');

  Client? _client;
  StdioClientTransport? _transport;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Client? get client => _client;
  Transport? get transport => _transport;

  /// Initialize the MCP client using STDIO transport (spawns Playwright MCP process)
  Future<void> initialize({String? serverUrl}) async {
    if (_isInitialized) {
      _logger.fine('Already initialized');
      return;
    }

    _logger.info('Initializing Playwright MCP via STDIO transport');

    // Create STDIO transport that spawns the Playwright MCP process
    // Note: Using full path since Flutter Process.start doesn't inherit shell PATH
    // Note: Using ProcessStartMode.normal because Flutter GUI apps don't have
    //       parent stdio to inherit (inheritStdio causes "stdio is not connected")
    _transport = StdioClientTransport(
      StdioServerParameters(
        command: '/home/hans/.nvm/versions/node/v24.11.1/bin/node',
        args: [
          '/home/hans/.nvm/versions/node/v24.11.1/lib/node_modules/@playwright/mcp/cli.js',
        ],
        environment: {
          'HOME': '/home/hans',
          'PATH':
              '/home/hans/.nvm/versions/node/v24.11.1/bin:/usr/local/bin:/usr/bin:/bin',
        },
        stderrMode: io.ProcessStartMode.normal, // Required for Flutter GUI apps
      ),
    );

    // Create and connect the MCP client
    _client = Client(
      const Implementation(name: 'GrowERP Browser Client', version: '1.0.0'),
    );

    await _client!.connect(_transport!);
    _isInitialized = true;
    _logger.info('BrowserMCP client initialized successfully via STDIO');
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

/// Factory function for creating the native implementation
FlutterMcpBrowserServiceImpl createBrowserServiceImpl() {
  return FlutterMcpBrowserServiceImpl();
}

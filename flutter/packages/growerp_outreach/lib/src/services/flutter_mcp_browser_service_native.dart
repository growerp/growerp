import 'dart:io' as io;
import 'package:logging/logging.dart' as logging;
import 'package:mcp_dart/mcp_dart.dart';

/// Configuration for MCP Playwright server paths
class McpServerConfig {
  /// Path to Node.js executable
  final String nodePath;

  /// Path to Playwright MCP CLI script
  final String playwrightMcpPath;

  /// HOME directory for the process
  final String homeDir;

  /// PATH environment variable
  final String pathEnv;

  const McpServerConfig({
    required this.nodePath,
    required this.playwrightMcpPath,
    required this.homeDir,
    required this.pathEnv,
  });

  /// Create config from environment variables with fallbacks
  factory McpServerConfig.fromEnvironment() {
    final home = io.Platform.environment['HOME'] ?? '/home/user';
    final nvmDir = io.Platform.environment['NVM_DIR'] ?? '$home/.nvm';

    // Try to detect Node.js version
    final nodeVersion = io.Platform.environment['NODE_VERSION'] ?? 'v24.11.1';
    final nodeBase = '$nvmDir/versions/node/$nodeVersion';

    return McpServerConfig(
      nodePath:
          io.Platform.environment['MCP_NODE_PATH'] ?? '$nodeBase/bin/node',
      playwrightMcpPath: io.Platform.environment['MCP_PLAYWRIGHT_PATH'] ??
          '$nodeBase/lib/node_modules/@playwright/mcp/cli.js',
      homeDir: home,
      pathEnv: io.Platform.environment['PATH'] ??
          '$nodeBase/bin:/usr/local/bin:/usr/bin:/bin',
    );
  }

  /// Create config for common Linux setup with nvm
  factory McpServerConfig.linux({
    String? homeDir,
    String nodeVersion = 'v24.11.1',
  }) {
    final home = homeDir ?? io.Platform.environment['HOME'] ?? '/home/user';
    final nodeBase = '$home/.nvm/versions/node/$nodeVersion';

    return McpServerConfig(
      nodePath: '$nodeBase/bin/node',
      playwrightMcpPath: '$nodeBase/lib/node_modules/@playwright/mcp/cli.js',
      homeDir: home,
      pathEnv: '$nodeBase/bin:/usr/local/bin:/usr/bin:/bin',
    );
  }

  /// Create config for system-installed Node.js
  factory McpServerConfig.system({String? homeDir}) {
    final home = homeDir ?? io.Platform.environment['HOME'] ?? '/home/user';

    return McpServerConfig(
      nodePath: '/usr/bin/node',
      playwrightMcpPath: '/usr/lib/node_modules/@playwright/mcp/cli.js',
      homeDir: home,
      pathEnv: '/usr/local/bin:/usr/bin:/bin',
    );
  }
}

/// Native (non-web) implementation using STDIO transport
class FlutterMcpBrowserServiceImpl {
  static final logging.Logger _logger =
      logging.Logger('outreach.FlutterMcpBrowserServiceImpl.native');

  /// Current configuration (can be changed before initialize)
  static McpServerConfig config = McpServerConfig.fromEnvironment();

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
    _logger.info('Node path: ${config.nodePath}');
    _logger.info('Playwright MCP path: ${config.playwrightMcpPath}');

    // Verify paths exist
    if (!io.File(config.nodePath).existsSync()) {
      throw StateError('Node.js not found at: ${config.nodePath}\n'
          'Set MCP_NODE_PATH environment variable or use McpServerConfig to configure.');
    }
    if (!io.File(config.playwrightMcpPath).existsSync()) {
      throw StateError(
          'Playwright MCP not found at: ${config.playwrightMcpPath}\n'
          'Install with: npm install -g @anthropic-ai/mcp-server-playwright\n'
          'Or set MCP_PLAYWRIGHT_PATH environment variable.');
    }

    // Create STDIO transport that spawns the Playwright MCP process
    // Note: Using ProcessStartMode.normal because Flutter GUI apps don't have
    //       parent stdio to inherit (inheritStdio causes "stdio is not connected")
    _transport = StdioClientTransport(
      StdioServerParameters(
        command: config.nodePath,
        args: [config.playwrightMcpPath],
        environment: {
          'HOME': config.homeDir,
          'PATH': config.pathEnv,
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

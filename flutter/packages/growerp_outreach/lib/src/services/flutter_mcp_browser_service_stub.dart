import 'package:mcp_dart/mcp_dart.dart';

/// Stub configuration - not used on this platform
class McpServerConfig {
  const McpServerConfig._();
}

/// Stub implementation - should never be instantiated directly
/// Used only for conditional imports
class FlutterMcpBrowserServiceImpl {
  McpClient? _client;
  Transport? _transport;
  final bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({String? serverUrl}) {
    throw UnsupportedError('Cannot create browser service on this platform');
  }

  Future<void> cleanup() async {}

  McpClient? get client => _client;
  Transport? get transport => _transport;
}

/// Factory function for creating the platform-specific implementation
FlutterMcpBrowserServiceImpl createBrowserServiceImpl() {
  throw UnsupportedError('Cannot create browser service on this platform');
}

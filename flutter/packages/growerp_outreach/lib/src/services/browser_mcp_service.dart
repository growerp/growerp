import 'snapshot_parser.dart';
import 'element_selector.dart';
import 'mcp_bridge.dart';
import '../utils/logger.dart';
import '../utils/retry_helper.dart';

/// BrowserMCP Service - Production Implementation with MCP Integration
///
/// Provides browser automation capabilities via browsermcp MCP server.
/// Uses actual MCP tools via HTTP bridge.
class BrowserMCPService with LoggerMixin {
  final MCPBridge _bridge;
  bool _isInitialized = false;
  String? _currentUrl;
  SnapshotElement? _lastSnapshot;

  BrowserMCPService({MCPBridge? bridge}) : _bridge = bridge ?? MCPBridge();

  /// Initialize the browser session
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.fine('Already initialized');
      return;
    }

    logger.info('Initializing browser session via MCP');

    try {
      // Browser is automatically available via MCP server
      // No explicit initialization needed for browsermcp
      _isInitialized = true;
      logger.info('Browser session initialized');
    } catch (e, stackTrace) {
      logger.severe('Failed to initialize browser', e, stackTrace);
      rethrow;
    }
  }

  /// Navigate to a URL with retry logic
  Future<void> navigate(String url) async {
    _ensureInitialized();

    await RetryHelper.retry(
      () async {
        logger.info('Navigating to: $url');

        // Call actual MCP tool via bridge
        await _bridge.navigate(url);
        _currentUrl = url;

        logger.fine('Navigation complete');
      },
      config: const RetryConfig(maxAttempts: 3),
    );
  }

  /// Take a snapshot of the current page and parse it
  Future<SnapshotElement> snapshot() async {
    _ensureInitialized();

    return await RetryHelper.retry(
      () async {
        logger.fine('Taking page snapshot via MCP');

        // Call actual MCP tool via bridge
        final snapshotData = await _bridge.snapshot();

        final root = SnapshotParser.parse(snapshotData);
        if (root == null) {
          throw Exception('Failed to parse snapshot');
        }

        _lastSnapshot = root;
        _currentUrl = snapshotData['url'] as String?;
        logger.fine('Snapshot captured: ${root.children.length} children');

        return root;
      },
      config: const RetryConfig(maxAttempts: 2),
    );
  }

  /// Get element selector for the last snapshot
  ElementSelector? get selector {
    if (_lastSnapshot == null) {
      logger.warning('No snapshot available, call snapshot() first');
      return null;
    }
    return ElementSelector(_lastSnapshot!);
  }

  /// Click an element on the page
  Future<void> click({
    required String element,
    required String ref,
  }) async {
    _ensureInitialized();

    await RetryHelper.retry(
      () async {
        logger.info('Clicking: $element');

        // Call actual MCP tool via bridge
        await _bridge.click(element: element, ref: ref);

        logger.fine('Click complete');
      },
      config: const RetryConfig(maxAttempts: 2),
    );
  }

  /// Click element found by selector
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

    await RetryHelper.retry(
      () async {
        logger.info(
            'Typing into $element: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

        // Call actual MCP tool via bridge
        await _bridge.type(
          element: element,
          ref: ref,
          text: text,
          submit: submit,
        );

        logger.fine('Typing complete');
      },
      config: const RetryConfig(maxAttempts: 2),
    );
  }

  /// Type into element found by selector
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

  /// Wait for a specified duration
  Future<void> wait(double seconds) async {
    _ensureInitialized();

    logger.fine('Waiting ${seconds}s');

    // Call actual MCP tool via bridge
    await _bridge.wait(seconds);
  }

  /// Take a screenshot of the current page
  Future<String?> screenshot() async {
    _ensureInitialized();

    logger.fine('Taking screenshot via MCP');

    // Call actual MCP tool via bridge
    return await _bridge.screenshot();
  }

  /// Go back to previous page
  Future<void> goBack() async {
    _ensureInitialized();

    logger.info('Going back');

    // Call actual MCP tool via bridge
    await _bridge.goBack();
  }

  /// Go forward to next page
  Future<void> goForward() async {
    _ensureInitialized();

    logger.info('Going forward');

    // Call actual MCP tool via bridge
    await _bridge.goForward();
  }

  /// Hover over an element
  Future<void> hover({
    required String element,
    required String ref,
  }) async {
    _ensureInitialized();

    logger.fine('Hovering over: $element');

    // Call actual MCP tool via bridge
    await _bridge.hover(element: element, ref: ref);
  }

  /// Press a key
  Future<void> pressKey(String key) async {
    _ensureInitialized();

    logger.fine('Pressing key: $key');

    // Call actual MCP tool via bridge
    await _bridge.pressKey(key);
  }

  /// Get current URL
  String? get currentUrl => _currentUrl;

  /// Get last snapshot
  SnapshotElement? get lastSnapshot => _lastSnapshot;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Cleanup and close browser session
  Future<void> cleanup() async {
    if (!_isInitialized) return;

    logger.info('Cleaning up browser session');

    // Browser session managed by MCP server
    // No explicit cleanup needed

    _isInitialized = false;
    _currentUrl = null;
    _lastSnapshot = null;

    logger.info('Browser session closed');
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'BrowserMCPService not initialized. Call initialize() first.');
    }
  }
}

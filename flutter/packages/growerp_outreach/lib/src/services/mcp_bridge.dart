import 'package:dio/dio.dart';
import '../utils/logger.dart';

/// MCP Bridge for calling browsermcp tools via HTTP
///
/// This bridge communicates with a local MCP HTTP server that
/// exposes the browsermcp MCP tools as REST endpoints.
class MCPBridge with LoggerMixin {
  final Dio _dio;
  final String baseUrl;

  MCPBridge({
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = baseUrl ?? 'http://localhost:3000/mcp',
        _dio = dio ?? Dio();

  /// Call an MCP tool
  Future<Map<String, dynamic>> call(
    String tool,
    Map<String, dynamic> params,
  ) async {
    try {
      logger.fine('Calling MCP tool: $tool with params: $params');

      final response = await _dio.post(
        '$baseUrl/$tool',
        data: params,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        logger.fine('MCP tool $tool completed successfully');
        return response.data as Map<String, dynamic>;
      } else {
        final error =
            'MCP tool $tool failed with status ${response.statusCode}';
        logger.warning(error);
        throw MCPException(error, response.data);
      }
    } on DioException catch (e) {
      final error = 'Failed to call MCP tool $tool: ${e.message}';
      logger.severe(error, e);
      throw MCPException(error, e.response?.data);
    }
  }

  /// Navigate to a URL
  Future<void> navigate(String url) async {
    await call('browser_navigate', {'url': url});
  }

  /// Take a snapshot
  Future<Map<String, dynamic>> snapshot() async {
    return await call('browser_snapshot', {});
  }

  /// Click an element
  Future<void> click({
    required String element,
    required String ref,
  }) async {
    await call('browser_click', {
      'element': element,
      'ref': ref,
    });
  }

  /// Type text
  Future<void> type({
    required String element,
    required String ref,
    required String text,
    bool submit = false,
  }) async {
    await call('browser_type', {
      'element': element,
      'ref': ref,
      'text': text,
      'submit': submit,
    });
  }

  /// Wait
  Future<void> wait(double seconds) async {
    await call('browser_wait', {'time': seconds});
  }

  /// Take screenshot
  Future<String> screenshot() async {
    final result = await call('browser_screenshot', {});
    return result['screenshot'] as String;
  }

  /// Go back
  Future<void> goBack() async {
    await call('browser_go_back', {});
  }

  /// Go forward
  Future<void> goForward() async {
    await call('browser_go_forward', {});
  }

  /// Hover over element
  Future<void> hover({
    required String element,
    required String ref,
  }) async {
    await call('browser_hover', {
      'element': element,
      'ref': ref,
    });
  }

  /// Press a key
  Future<void> pressKey(String key) async {
    await call('browser_press_key', {'key': key});
  }

  /// Select option in dropdown
  Future<void> selectOption({
    required String element,
    required String ref,
    required List<String> values,
  }) async {
    await call('browser_select_option', {
      'element': element,
      'ref': ref,
      'values': values,
    });
  }

  /// Get console logs
  Future<List<String>> getConsoleLogs() async {
    final result = await call('browser_get_console_logs', {});
    return (result['logs'] as List).cast<String>();
  }
}

/// MCP Exception
class MCPException implements Exception {
  final String message;
  final dynamic details;

  MCPException(this.message, [this.details]);

  @override
  String toString() =>
      'MCPException: $message${details != null ? '\nDetails: $details' : ''}';
}

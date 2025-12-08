import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Outreach system logger
class OutreachLogger {
  static final Map<String, Logger> _loggers = {};
  static bool _initialized = false;

  /// Initialize logging system
  static void initialize({Level level = Level.INFO}) {
    if (_initialized) return;

    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      // Format: [LEVEL] ClassName.method: message
      final className = record.loggerName.split('.').last;
      debugPrint(
        '[${record.level.name}] $className: ${record.message}',
      );

      if (record.error != null) {
        debugPrint('  Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('  Stack: ${record.stackTrace}');
      }
    });

    _initialized = true;
  }

  /// Get logger for a specific class
  static Logger getLogger(String name) {
    if (!_initialized) {
      initialize();
    }

    return _loggers.putIfAbsent(name, () => Logger(name));
  }
}

/// Logger mixin for easy logging in classes
mixin LoggerMixin {
  Logger get logger => OutreachLogger.getLogger(runtimeType.toString());
}

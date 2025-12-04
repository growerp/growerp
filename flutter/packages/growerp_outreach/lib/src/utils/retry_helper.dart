import 'dart:async';
import 'package:logging/logging.dart';

/// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });
}

/// Retry helper with exponential backoff
class RetryHelper {
  static final _logger = Logger('RetryHelper');

  /// Execute function with retry logic
  static Future<T> retry<T>(
    Future<T> Function() fn, {
    RetryConfig config = const RetryConfig(),
    bool Function(dynamic error)? retryIf,
  }) async {
    var attempt = 0;
    var delay = config.initialDelay;

    while (true) {
      attempt++;

      try {
        _logger.fine('Attempt $attempt/${config.maxAttempts}');
        return await fn();
      } catch (error, stackTrace) {
        final shouldRetry = retryIf?.call(error) ?? true;

        if (attempt >= config.maxAttempts || !shouldRetry) {
          _logger.severe(
            'Failed after $attempt attempts',
            error,
            stackTrace,
          );
          rethrow;
        }

        _logger.warning(
          'Attempt $attempt failed, retrying in ${delay.inSeconds}s',
          error,
        );

        await Future.delayed(delay);

        // Exponential backoff
        delay = Duration(
          milliseconds:
              (delay.inMilliseconds * config.backoffMultiplier).toInt(),
        );

        // Cap at max delay
        if (delay > config.maxDelay) {
          delay = config.maxDelay;
        }
      }
    }
  }
}

import 'dart:async';
import 'package:logging/logging.dart';

/// Rate limiter for API/action throttling
class RateLimiter {
  final String name;
  final int maxRequests;
  final Duration window;
  final _logger = Logger('RateLimiter');

  final List<DateTime> _requests = [];
  final _lock = Completer<void>()..complete();

  RateLimiter({
    required this.name,
    required this.maxRequests,
    required this.window,
  });

  /// Execute action with rate limiting
  Future<T> execute<T>(Future<T> Function() action) async {
    await _lock.future;

    final now = DateTime.now();
    final windowStart = now.subtract(window);

    // Remove old requests outside the window
    _requests.removeWhere((time) => time.isBefore(windowStart));

    // Check if we're at the limit
    if (_requests.length >= maxRequests) {
      final oldestRequest = _requests.first;
      final waitTime = oldestRequest.add(window).difference(now);

      if (waitTime.isNegative) {
        // Window has passed, can proceed
        _requests.removeAt(0);
      } else {
        // Need to wait
        _logger.info(
          '$name: Rate limit reached, waiting ${waitTime.inSeconds}s',
        );
        await Future.delayed(waitTime);
        return execute(action); // Retry after waiting
      }
    }

    // Record this request
    _requests.add(now);

    try {
      return await action();
    } catch (e) {
      // Remove the request if it failed
      _requests.removeLast();
      rethrow;
    }
  }

  /// Get current usage stats
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final windowStart = now.subtract(window);
    final activeRequests =
        _requests.where((t) => t.isAfter(windowStart)).length;

    return {
      'name': name,
      'active_requests': activeRequests,
      'max_requests': maxRequests,
      'window_seconds': window.inSeconds,
      'utilization': (activeRequests / maxRequests * 100).toStringAsFixed(1),
    };
  }

  /// Reset the rate limiter
  void reset() {
    _requests.clear();
    _logger.info('$name: Rate limiter reset');
  }
}

/// Platform-specific rate limiters
class PlatformRateLimiters {
  static final twitter = RateLimiter(
    name: 'Twitter',
    maxRequests: 50,
    window: const Duration(hours: 1),
  );

  static final linkedin = RateLimiter(
    name: 'LinkedIn',
    maxRequests: 100,
    window: const Duration(hours: 1),
  );

  static final email = RateLimiter(
    name: 'Email',
    maxRequests: 500,
    window: const Duration(hours: 1),
  );

  static RateLimiter forPlatform(String platform) {
    switch (platform.toUpperCase()) {
      case 'TWITTER':
        return twitter;
      case 'LINKEDIN':
        return linkedin;
      case 'EMAIL':
        return email;
      default:
        throw ArgumentError('Unknown platform: $platform');
    }
  }
}

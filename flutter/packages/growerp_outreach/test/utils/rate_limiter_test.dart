/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_outreach/src/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('should allow requests within limit', () async {
      final limiter = RateLimiter(
        name: 'Test',
        maxRequests: 3,
        window: const Duration(seconds: 10),
      );

      var counter = 0;

      // Execute 3 requests - all should succeed immediately
      await limiter.execute(() async => counter++);
      await limiter.execute(() async => counter++);
      await limiter.execute(() async => counter++);

      expect(counter, equals(3));
    });

    test('should return correct stats', () {
      final limiter = RateLimiter(
        name: 'TestStats',
        maxRequests: 10,
        window: const Duration(hours: 1),
      );

      final stats = limiter.getStats();

      expect(stats['name'], equals('TestStats'));
      expect(stats['max_requests'], equals(10));
      expect(stats['window_seconds'], equals(3600));
      expect(stats['active_requests'], equals(0));
    });

    test('should track active requests', () async {
      final limiter = RateLimiter(
        name: 'TestTracking',
        maxRequests: 5,
        window: const Duration(minutes: 1),
      );

      // Execute some requests
      await limiter.execute(() async => 1);
      await limiter.execute(() async => 2);

      final stats = limiter.getStats();
      expect(stats['active_requests'], equals(2));
    });

    test('should reset correctly', () async {
      final limiter = RateLimiter(
        name: 'TestReset',
        maxRequests: 3,
        window: const Duration(minutes: 1),
      );

      await limiter.execute(() async => 1);
      await limiter.execute(() async => 2);

      expect(limiter.getStats()['active_requests'], equals(2));

      limiter.reset();

      expect(limiter.getStats()['active_requests'], equals(0));
    });

    test('should remove failed request from tracking', () async {
      final limiter = RateLimiter(
        name: 'TestFailure',
        maxRequests: 5,
        window: const Duration(minutes: 1),
      );

      await limiter.execute(() async => 'success');

      expect(limiter.getStats()['active_requests'], equals(1));

      // Try an action that throws
      try {
        await limiter.execute(() async => throw Exception('Test error'));
      } catch (_) {
        // Expected
      }

      // Failed request should be removed
      expect(limiter.getStats()['active_requests'], equals(1));
    });
  });

  group('PlatformRateLimiters', () {
    test('should return Twitter limiter', () {
      final limiter = PlatformRateLimiters.forPlatform('TWITTER');
      expect(limiter.name, equals('Twitter'));
    });

    test('should return LinkedIn limiter', () {
      final limiter = PlatformRateLimiters.forPlatform('linkedin');
      expect(limiter.name, equals('LinkedIn'));
    });

    test('should return Email limiter', () {
      final limiter = PlatformRateLimiters.forPlatform('Email');
      expect(limiter.name, equals('Email'));
    });

    test('should throw for unknown platform', () {
      expect(
        () => PlatformRateLimiters.forPlatform('unknown'),
        throwsArgumentError,
      );
    });

    test('should have correct limits for Twitter', () {
      final stats = PlatformRateLimiters.twitter.getStats();
      expect(stats['max_requests'], equals(50));
      expect(stats['window_seconds'], equals(3600)); // 1 hour
    });

    test('should have correct limits for LinkedIn', () {
      final stats = PlatformRateLimiters.linkedin.getStats();
      expect(stats['max_requests'], equals(100));
      expect(stats['window_seconds'], equals(3600)); // 1 hour
    });

    test('should have correct limits for Email', () {
      final stats = PlatformRateLimiters.email.getStats();
      expect(stats['max_requests'], equals(500));
      expect(stats['window_seconds'], equals(3600)); // 1 hour
    });
  });
}

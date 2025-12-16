import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import 'platform_automation_adapter.dart';
import 'adapters/email_automation_adapter.dart';
import 'adapters/linkedin_automation_adapter.dart';
import 'adapters/x_automation_adapter.dart';
import '../utils/rate_limiter.dart';

/// Orchestrates automation across multiple platforms
///
/// This class manages the execution of outreach campaigns across
/// different platforms, handling platform-specific adapters and
/// coordinating the automation workflow.
class AutomationOrchestrator {
  AutomationOrchestrator(this.restClient);

  final RestClient restClient;
  final Map<String, PlatformAutomationAdapter> _adapters = {};
  final Map<String, RateLimiter> _rateLimiters = {};

  /// Get or create a rate limiter for a platform
  RateLimiter _getRateLimiter(String platform) {
    return _rateLimiters.putIfAbsent(platform, () {
      // Configure rate limits per platform
      // These are conservative defaults to avoid platform detection
      switch (platform.toUpperCase()) {
        case 'EMAIL':
          // 60 emails per hour (1 per minute)
          return RateLimiter(
            name: 'EMAIL',
            maxRequests: 60,
            window: const Duration(hours: 1),
          );
        case 'LINKEDIN':
          // 20 actions per hour (to stay under radar)
          return RateLimiter(
            name: 'LINKEDIN',
            maxRequests: 20,
            window: const Duration(hours: 1),
          );
        case 'TWITTER':
          // 15 actions per hour (Twitter is strict)
          return RateLimiter(
            name: 'TWITTER',
            maxRequests: 15,
            window: const Duration(hours: 1),
          );
        default:
          return RateLimiter(
            name: platform,
            maxRequests: 30,
            window: const Duration(hours: 1),
          );
      }
    });
  }

  /// Initialize adapters for the specified platforms
  Future<void> initialize(List<String> platforms) async {
    for (final platform in platforms) {
      final adapter = _createAdapter(platform);
      if (adapter != null) {
        await adapter.initialize();
        _adapters[platform] = adapter;
      }
    }
  }

  /// Run automation for a specific platform
  ///
  /// If [targetLeads] is provided and non-empty, those profiles will be used
  /// directly instead of searching with [searchCriteria].
  Future<void> runAutomation({
    required String platform,
    required String searchCriteria,
    required String messageTemplate,
    required int dailyLimit,
    required String campaignId,
    String? emailSubject,
    List<ProfileData>? targetLeads,
    required bool Function() checkCancelled,
  }) async {
    final adapter = _adapters[platform];
    if (adapter == null) {
      throw Exception('Platform $platform not initialized');
    }

    // Check if logged in
    final isLoggedIn = await adapter.isLoggedIn();
    if (!isLoggedIn) {
      throw Exception('Not logged in to $platform');
    }

    // Use target leads if provided, otherwise search for profiles
    final List<ProfileData> profiles;
    if (targetLeads != null && targetLeads.isNotEmpty) {
      profiles = targetLeads;
      debugPrint('Using ${profiles.length} target leads for $platform');
    } else {
      profiles = await adapter.searchProfiles(searchCriteria);
      debugPrint('Found ${profiles.length} profiles via search for $platform');
    }

    // Get rate limiter for this platform
    final rateLimiter = _getRateLimiter(platform);

    // Send messages up to daily limit
    int sent = 0;
    for (final profile in profiles) {
      if (checkCancelled()) break;
      if (sent >= dailyLimit) break;

      try {
        // Use rate limiter to control send rate
        await rateLimiter.execute(() async {
          // Personalize message
          final message = _personalizeMessage(messageTemplate, profile);

          // Send message (or connection request for social platforms)
          if (platform == 'EMAIL') {
            await adapter.sendDirectMessage(
              profile,
              message,
              campaignId: campaignId,
              subject: emailSubject,
            );
          } else {
            await adapter.sendConnectionRequest(profile, message);
          }

          // Record success in backend
          await restClient.createOutreachMessage(
            marketingCampaignId: campaignId,
            platform: platform,
            recipientName: profile.name,
            recipientHandle: profile.handle,
            recipientProfileUrl: profile.profileUrl,
            recipientEmail: profile.email,
            messageContent: message,
            status: 'SENT',
          );

          sent++;

          // Add small random delay on top of rate limiting to appear more human
          if (!checkCancelled()) {
            final jitter =
                DateTime.now().millisecond % 10; // 0-10 seconds extra
            await Future.delayed(Duration(seconds: jitter));
          }
        });
      } catch (e) {
        // Log error and continue
        debugPrint('Error sending to ${profile.name}: $e');

        // Record failure in backend
        try {
          await restClient.createOutreachMessage(
            marketingCampaignId: campaignId,
            platform: platform,
            recipientName: profile.name,
            recipientHandle: profile.handle,
            recipientProfileUrl: profile.profileUrl,
            recipientEmail: profile.email,
            messageContent: _personalizeMessage(messageTemplate, profile),
            status: 'FAILED',
          );
        } catch (_) {
          // Ignore backend error if logging fails
        }
      }
    }

    // Log rate limiter stats at end
    debugPrint('Rate limiter stats: ${rateLimiter.getStats()}');
  }

  /// Cleanup all adapters and reset rate limiters
  Future<void> cleanup() async {
    for (final adapter in _adapters.values) {
      await adapter.cleanup();
    }
    _adapters.clear();

    for (final limiter in _rateLimiters.values) {
      limiter.reset();
    }
    _rateLimiters.clear();
  }

  /// Get rate limiter stats for a platform
  Map<String, dynamic>? getRateLimiterStats(String platform) {
    return _rateLimiters[platform]?.getStats();
  }

  PlatformAutomationAdapter? _createAdapter(String platform) {
    switch (platform.toUpperCase()) {
      case 'EMAIL':
        return EmailAutomationAdapter(restClient);
      case 'LINKEDIN':
        return LinkedInAutomationAdapter();
      case 'TWITTER':
        return XAutomationAdapter();
      default:
        return null;
    }
  }

  String _personalizeMessage(String template, ProfileData profile) {
    return template
        .replaceAll('{name}', profile.name)
        .replaceAll('{company}', profile.company ?? '')
        .replaceAll('{title}', profile.title ?? '');
  }
}

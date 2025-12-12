import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import 'platform_automation_adapter.dart';
import 'adapters/email_automation_adapter.dart';
import 'adapters/linkedin_automation_adapter.dart';
import 'adapters/x_automation_adapter.dart';

/// Orchestrates automation across multiple platforms
///
/// This class manages the execution of outreach campaigns across
/// different platforms, handling platform-specific adapters and
/// coordinating the automation workflow.
class AutomationOrchestrator {
  AutomationOrchestrator(this.restClient);

  final RestClient restClient;
  final Map<String, PlatformAutomationAdapter> _adapters = {};

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
  Future<void> runAutomation({
    required String platform,
    required String searchCriteria,
    required String messageTemplate,
    required int dailyLimit,
    required String campaignId,
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

    // Search for profiles
    final profiles = await adapter.searchProfiles(searchCriteria);

    // Send messages up to daily limit
    int sent = 0;
    for (final profile in profiles) {
      if (checkCancelled()) break;
      if (sent >= dailyLimit) break;

      try {
        // Personalize message
        final message = _personalizeMessage(messageTemplate, profile);

        // Send message (or connection request for social platforms)
        if (platform == 'EMAIL') {
          await adapter.sendDirectMessage(profile, message);
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

        // Add delay to mimic human behavior
        if (!checkCancelled()) {
          await Future.delayed(Duration(seconds: _getRandomDelay(platform)));
        }
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
  }

  /// Cleanup all adapters
  Future<void> cleanup() async {
    for (final adapter in _adapters.values) {
      await adapter.cleanup();
    }
    _adapters.clear();
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

  int _getRandomDelay(String platform) {
    // Different delays for different platforms
    switch (platform.toUpperCase()) {
      case 'EMAIL':
        return 30 + (DateTime.now().millisecond % 30); // 30-60 seconds
      case 'LINKEDIN':
        return 120 + (DateTime.now().millisecond % 180); // 2-5 minutes
      case 'TWITTER':
        return 180 + (DateTime.now().millisecond % 240); // 3-7 minutes
      default:
        return 60;
    }
  }
}

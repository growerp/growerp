import 'dart:math';
import '../platform_automation_adapter.dart';
import '../flutter_mcp_browser_service.dart';
import '../snapshot_parser.dart';
import '../../utils/rate_limiter.dart';

/// LinkedIn automation adapter using browsermcp via flutter_mcp
///
/// This adapter uses the flutter_mcp package to communicate with
/// browsermcp MCP server for LinkedIn profile searches, connection
/// requests, and direct messages. No separate HTTP bridge needed.
class LinkedInAutomationAdapter implements PlatformAutomationAdapter {
  final FlutterMcpBrowserService _browser;
  bool _initialized = false;

  /// Create adapter with optional browser service for testing
  LinkedInAutomationAdapter({FlutterMcpBrowserService? browser})
      : _browser = browser ?? FlutterMcpBrowserService();

  @override
  String get platformName => 'LINKEDIN';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _browser.initialize();
    await _browser.navigate('https://www.linkedin.com');
    _initialized = true;
  }

  @override
  Future<bool> isLoggedIn() async {
    if (!_initialized) return false;
    try {
      final snapshot = await _browser.snapshot();
      // Check for elements that only appear when logged in
      // Look for navigation elements like "Home", "My Network", "Messaging"
      final homeNav = SnapshotParser.findByText(snapshot, 'Home');
      final messagingNav = SnapshotParser.findByText(snapshot, 'Messaging');
      return homeNav != null || messagingNav != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ProfileData>> searchProfiles(String criteria) async {
    // Navigate to LinkedIn search
    final searchUrl = 'https://www.linkedin.com/search/results/people/'
        '?keywords=${Uri.encodeComponent(criteria)}';
    await _browser.navigate(searchUrl);
    await _browser.wait(3000);

    // Get page snapshot and parse profiles
    final snapshot = await _browser.snapshot();

    // Parse profiles from search results using SnapshotParser
    final profiles = <ProfileData>[];

    // Find all link elements that might be profile links
    final links = SnapshotParser.findAll(
      snapshot,
      role: 'link',
      predicate: (element) {
        // LinkedIn profile links contain '/in/' in their value or attributes
        final href = element.getAttribute('href') ?? element.value ?? '';
        return href.contains('/in/');
      },
    );

    for (final link in links) {
      final href = link.getAttribute('href') ?? link.value ?? '';
      final name = link.name?.trim();
      if (name != null && name.isNotEmpty && href.contains('/in/')) {
        // Extract just the /in/username part
        final inMatch = RegExp(r'/in/[^/?]+').firstMatch(href);
        if (inMatch != null) {
          profiles.add(ProfileData(
            name: name,
            profileUrl: 'https://www.linkedin.com${inMatch.group(0)}',
          ));
        }
      }
    }

    return profiles;
  }

  @override
  Future<void> sendConnectionRequest(
    ProfileData profile,
    String message,
  ) async {
    if (profile.profileUrl == null) {
      throw ArgumentError('Profile URL is required');
    }

    // Navigate to profile
    await _browser.navigate(profile.profileUrl!);
    await _browser.wait(2000);

    // Click Connect button
    await _browser.click(element: 'Connect', ref: 'connect-button');
    await _browser.wait(1000);

    // Click "Add a note" if message is provided
    if (message.isNotEmpty) {
      await _browser.click(element: 'Add a note', ref: 'add-note-button');
      await _browser.wait(500);

      // Type personalized message
      await _browser.type(
        element: 'note textarea',
        ref: 'note-input',
        text: message,
      );
    }

    // Click Send
    await _browser.click(element: 'Send', ref: 'send-button');
    await _browser.wait(1000);
  }

  @override
  Future<void> sendDirectMessage(
    ProfileData profile,
    String message, {
    String? campaignId,
    String? subject,
  }) async {
    if (profile.profileUrl == null) {
      throw ArgumentError('Profile URL is required');
    }

    // Navigate to profile
    await _browser.navigate(profile.profileUrl!);
    await _browser.wait(2000);

    // Click Message button
    await _browser.click(element: 'Message', ref: 'message-button');
    await _browser.wait(1000);

    // Type message
    await _browser.type(
      element: 'message input',
      ref: 'message-input',
      text: message,
    );

    // Send message
    await _browser.click(element: 'Send', ref: 'send-message-button');
    await _browser.wait(1000);
  }

  /// Get 1st-level connections from LinkedIn My Network page
  ///
  /// Navigates to the connections list and extracts profile data.
  /// [maxResults] limits the number of connections to return.
  /// [scrollCount] determines how many times to scroll for more results.
  Future<List<ProfileData>> getFirstLevelConnections({
    int maxResults = 50,
    int scrollCount = 3,
  }) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    // Navigate to connections list
    await _browser.navigate(
        'https://www.linkedin.com/mynetwork/invite-connect/connections/');
    await _browser.wait(3000);

    final profiles = <ProfileData>[];
    final seenUrls = <String>{};

    for (var scroll = 0; scroll <= scrollCount; scroll++) {
      // Get page snapshot
      final snapshot = await _browser.snapshot();

      // Find connection cards - they contain profile links with /in/
      final links = SnapshotParser.findAll(
        snapshot,
        role: 'link',
        predicate: (element) {
          final href = element.getAttribute('href') ?? element.value ?? '';
          return href.contains('/in/');
        },
      );

      for (final link in links) {
        if (profiles.length >= maxResults) break;

        final href = link.getAttribute('href') ?? link.value ?? '';
        final name = link.name?.trim();

        if (name != null && name.isNotEmpty && href.contains('/in/')) {
          final inMatch = RegExp(r'/in/[^/?]+').firstMatch(href);
          if (inMatch != null) {
            final profileUrl = 'https://www.linkedin.com${inMatch.group(0)}';

            // Avoid duplicates
            if (!seenUrls.contains(profileUrl)) {
              seenUrls.add(profileUrl);
              profiles.add(ProfileData(
                name: name,
                profileUrl: profileUrl,
                isConnection: true, // Mark as 1st-level connection
              ));
            }
          }
        }
      }

      if (profiles.length >= maxResults) break;

      // Scroll down to load more connections
      if (scroll < scrollCount) {
        await _browser.scroll(direction: 'down');
        await _browser.wait(2000);
      }
    }

    return profiles;
  }

  /// Send messages to multiple 1st-level connections with rate limiting
  ///
  /// [connections] - List of profiles to message
  /// [messageTemplate] - Message template with {name} placeholder
  /// [variables] - Optional additional variables for template substitution
  /// [delayBetweenMessages] - Base delay between messages (randomized +/- 5s)
  Future<List<MessageResult>> sendBatchMessages({
    required List<ProfileData> connections,
    required String messageTemplate,
    Map<String, String>? variables,
    Duration delayBetweenMessages = const Duration(seconds: 10),
  }) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    final results = <MessageResult>[];
    final rateLimiter = PlatformRateLimiters.linkedin;
    final random = Random();

    for (var i = 0; i < connections.length; i++) {
      final connection = connections[i];

      try {
        // Personalize message with name
        var message = messageTemplate.replaceAll('{name}', connection.name);

        // Apply additional variables
        if (variables != null) {
          for (final entry in variables.entries) {
            message = message.replaceAll('{${entry.key}}', entry.value);
          }
        }

        // Execute with rate limiting
        await rateLimiter.execute(() async {
          await sendDirectMessage(connection, message);
        });

        results.add(MessageResult(
          profile: connection,
          success: true,
        ));

        // Random delay between messages (human-like behavior)
        if (i < connections.length - 1) {
          final variance = random.nextInt(10) - 5; // -5 to +5 seconds
          final delay = Duration(
            seconds: delayBetweenMessages.inSeconds + variance,
          );
          await Future.delayed(delay);
        }
      } catch (e) {
        results.add(MessageResult(
          profile: connection,
          success: false,
          error: e.toString(),
        ));
      }
    }

    return results;
  }

  /// Check if a profile is a 1st-level connection
  ///
  /// Navigates to the profile and checks for "Message" button presence
  /// (vs "Connect" button for non-connections)
  Future<bool> isFirstLevelConnection(ProfileData profile) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    if (profile.profileUrl == null) {
      throw ArgumentError('Profile URL is required');
    }

    await _browser.navigate(profile.profileUrl!);
    await _browser.wait(2000);

    final snapshot = await _browser.snapshot();

    // 1st-level connections show "Message" button directly
    // Non-connections show "Connect" button
    final messageButton = SnapshotParser.findByText(snapshot, 'Message');
    final connectButton = SnapshotParser.findByText(snapshot, 'Connect');

    // If Message button exists and Connect doesn't, it's a 1st-level connection
    return messageButton != null && connectButton == null;
  }

  @override
  Future<void> cleanup() async {
    await _browser.cleanup();
    _initialized = false;
  }
}

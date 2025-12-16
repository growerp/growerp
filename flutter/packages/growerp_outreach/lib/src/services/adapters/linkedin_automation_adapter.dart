import '../platform_automation_adapter.dart';
import '../flutter_mcp_browser_service.dart';
import '../snapshot_parser.dart';

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

  @override
  Future<void> cleanup() async {
    await _browser.cleanup();
    _initialized = false;
  }
}

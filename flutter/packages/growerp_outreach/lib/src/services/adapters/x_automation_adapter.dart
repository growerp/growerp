import 'package:flutter/foundation.dart';
import '../platform_automation_adapter.dart';
import '../flutter_mcp_browser_service.dart';
import '../snapshot_parser.dart';

/// X (formerly Twitter) automation adapter using browsermcp via flutter_mcp
///
/// This adapter uses the flutter_mcp package to communicate with
/// browsermcp MCP server for X profile searches, follows, and direct messages.
/// No separate HTTP bridge needed.
class XAutomationAdapter implements PlatformAutomationAdapter {
  final FlutterMcpBrowserService _browser;
  bool _initialized = false;

  /// Create adapter with optional browser service for testing
  XAutomationAdapter({FlutterMcpBrowserService? browser})
      : _browser = browser ?? FlutterMcpBrowserService();

  @override
  String get platformName => 'TWITTER';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await _browser.initialize();

    // Navigate to Twitter/X
    await _browser.navigate('https://twitter.com');

    // Wait for page load
    await _browser.wait(2000);

    _initialized = true;
  }

  @override
  Future<bool> isLoggedIn() async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    try {
      // Take snapshot and check for logged-in indicators
      final snapshot = await _browser.snapshot();

      // Check if we can see the home timeline or profile elements
      // Look for Tweet compose button or profile navigation
      final tweetButton = SnapshotParser.findFirst(
        snapshot,
        testId: 'tweetButton',
      );
      final homeTimeline = SnapshotParser.findByText(snapshot, 'Home');

      // If we can find these elements, we're logged in
      return tweetButton != null || homeTimeline != null;
    } catch (e) {
      debugPrint('Error checking Twitter login status: $e');
      return false;
    }
  }

  @override
  Future<List<ProfileData>> searchProfiles(String criteria) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    final profiles = <ProfileData>[];

    try {
      // Navigate to Twitter search with user filter
      final searchUrl =
          'https://twitter.com/search?q=${Uri.encodeComponent(criteria)}&f=user';
      await _browser.navigate(searchUrl);

      // Wait for search results to load
      await _browser.wait(2000);

      // Take snapshot to get search results
      final snapshot = await _browser.snapshot();

      // Find user cells in the snapshot
      final userCells = SnapshotParser.findAll(
        snapshot,
        testId: 'UserCell',
      );

      for (final cell in userCells) {
        // Extract profile data from cell
        final nameElement = SnapshotParser.findFirst(
          cell,
          role: 'link',
        );
        if (nameElement != null) {
          final href = nameElement.getAttribute('href') ?? '';
          final name = nameElement.name ?? '';
          if (href.isNotEmpty && name.isNotEmpty) {
            profiles.add(ProfileData(
              name: name,
              profileUrl: 'https://twitter.com$href',
              handle: href.startsWith('/') ? '@${href.substring(1)}' : href,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching Twitter profiles: $e');
    }

    return profiles;
  }

  @override
  Future<void> sendConnectionRequest(
    ProfileData profile,
    String message,
  ) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    if (profile.profileUrl == null) {
      throw ArgumentError('Profile URL is required for Twitter follow');
    }

    try {
      // Navigate to profile
      await _browser.navigate(profile.profileUrl!);
      await _browser.wait(1500);

      // Take snapshot to find follow button
      final snapshot = await _browser.snapshot();

      // Find follow button by test ID
      final followButton = SnapshotParser.findFirst(
            snapshot,
            testId: 'follow',
          ) ??
          SnapshotParser.findButton(snapshot, 'Follow');

      if (followButton != null) {
        await _browser.clickElement(followButton);
        await _browser.wait(500);
        debugPrint('✓ Followed ${profile.handle ?? profile.name} on Twitter');
      } else {
        throw Exception('Follow button not found');
      }
    } catch (e) {
      throw Exception('Failed to follow Twitter profile: $e');
    }
  }

  @override
  Future<void> sendDirectMessage(
    ProfileData profile,
    String message, {
    String? campaignId,
    String? subject,
  }) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    if (profile.profileUrl == null) {
      throw ArgumentError('Profile URL is required for Twitter DM');
    }

    try {
      // Navigate to profile
      await _browser.navigate(profile.profileUrl!);
      await _browser.wait(1500);

      // Take snapshot to find message button
      var snapshot = await _browser.snapshot();

      // Find and click message button
      final messageButton = SnapshotParser.findFirst(
            snapshot,
            testId: 'sendDMFromProfile',
          ) ??
          SnapshotParser.findButton(snapshot, 'Message');

      if (messageButton == null) {
        throw Exception('Message button not found');
      }

      await _browser.clickElement(messageButton);
      await _browser.wait(1000);

      // Take new snapshot to find message input
      snapshot = await _browser.snapshot();

      // Find message input field
      final messageInput = SnapshotParser.findFirst(
            snapshot,
            testId: 'dmComposerTextInput',
          ) ??
          SnapshotParser.findInput(snapshot,
              placeholder: 'Start a new message');

      if (messageInput == null) {
        throw Exception('Message input not found');
      }

      await _browser.typeIntoElement(messageInput, message);
      await _browser.wait(300);

      // Find and click send button
      snapshot = await _browser.snapshot();
      final sendButton = SnapshotParser.findFirst(
            snapshot,
            testId: 'dmComposerSendButton',
          ) ??
          SnapshotParser.findButton(snapshot, 'Send');

      if (sendButton == null) {
        throw Exception('Send button not found');
      }

      await _browser.clickElement(sendButton);
      await _browser.wait(500);

      debugPrint('✓ Sent DM to ${profile.handle ?? profile.name}: $message');
    } catch (e) {
      throw Exception('Failed to send Twitter DM: $e');
    }
  }

  @override
  Future<void> cleanup() async {
    await _browser.cleanup();
    _initialized = false;
  }
}

import 'package:flutter/foundation.dart';
import '../platform_automation_adapter.dart';
import '../flutter_mcp_browser_service.dart';
import '../snapshot_parser.dart';

/// Substack automation adapter using browsermcp via flutter_mcp
///
/// This adapter uses the flutter_mcp package to communicate with
/// browsermcp MCP server for Substack profile searches, follows, and notes.
/// No separate HTTP bridge needed.
///
/// Substack supports:
/// - Following writers
/// - Sending notes (short-form posts/comments)
/// - Commenting on posts
class SubstackAutomationAdapter implements PlatformAutomationAdapter {
  final FlutterMcpBrowserService _browser;
  bool _initialized = false;

  /// Create adapter with optional browser service for testing
  SubstackAutomationAdapter({FlutterMcpBrowserService? browser})
      : _browser = browser ?? FlutterMcpBrowserService();

  @override
  String get platformName => 'SUBSTACK';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await _browser.initialize();

    // Navigate to Substack
    await _browser.navigate('https://substack.com');

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

      // Check for user menu or profile elements that indicate login
      // Substack shows "Write" or user avatar when logged in
      final writeButton = SnapshotParser.findByText(snapshot, 'Write');
      final notesLink = SnapshotParser.findByText(snapshot, 'Notes');
      final homeLink = SnapshotParser.findByText(snapshot, 'Home');

      // If we can find these elements, we're logged in
      return writeButton != null || notesLink != null || homeLink != null;
    } catch (e) {
      debugPrint('Error checking Substack login status: $e');
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
      // Navigate to Substack search
      final searchUrl =
          'https://substack.com/search/${Uri.encodeComponent(criteria)}?type=publications';
      await _browser.navigate(searchUrl);

      // Wait for search results to load
      await _browser.wait(3000);

      // Take snapshot to get search results
      final snapshot = await _browser.snapshot();

      // Find publication links in the snapshot
      final links = SnapshotParser.findAll(
        snapshot,
        role: 'link',
        predicate: (element) {
          final href = element.getAttribute('href') ?? element.value ?? '';
          // Substack publication URLs are like https://username.substack.com
          // or https://substack.com/@username
          return href.contains('.substack.com') ||
              href.contains('substack.com/@');
        },
      );

      final seenUrls = <String>{};
      for (final link in links) {
        final href = link.getAttribute('href') ?? link.value ?? '';
        final name = link.name?.trim();

        if (name != null && name.isNotEmpty && !seenUrls.contains(href)) {
          seenUrls.add(href);

          // Extract handle from URL
          String? handle;
          if (href.contains('substack.com/@')) {
            final match = RegExp(r'substack\.com/@([^/?]+)').firstMatch(href);
            handle = match?.group(1);
          } else if (href.contains('.substack.com')) {
            final match =
                RegExp(r'https?://([^.]+)\.substack\.com').firstMatch(href);
            handle = match?.group(1);
          }

          profiles.add(ProfileData(
            name: name,
            profileUrl: href,
            handle: handle,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error searching Substack profiles: $e');
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
      throw ArgumentError('Profile URL is required');
    }

    try {
      // Navigate to the publication
      await _browser.navigate(profile.profileUrl!);
      await _browser.wait(2000);

      // Look for Subscribe/Follow button
      final snapshot = await _browser.snapshot();

      // Try to find Subscribe button (free subscription)
      final subscribeButton = SnapshotParser.findByText(snapshot, 'Subscribe');
      final followButton = SnapshotParser.findByText(snapshot, 'Follow');

      if (subscribeButton != null) {
        await _browser.clickElement(subscribeButton);
        await _browser.wait(1000);

        // If there's a free option, select it
        final freeOption =
            SnapshotParser.findByText(await _browser.snapshot(), 'Free');
        if (freeOption != null) {
          await _browser.clickElement(freeOption);
          await _browser.wait(1000);
        }
      } else if (followButton != null) {
        await _browser.clickElement(followButton);
        await _browser.wait(1000);
      }

      debugPrint('Subscribed/followed ${profile.name} on Substack');
    } catch (e) {
      debugPrint('Error following on Substack: $e');
      rethrow;
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

    // Substack doesn't have traditional DMs
    // Instead, we can:
    // 1. Comment on their latest post
    // 2. Send a note mentioning them
    // We'll use the Notes feature to send a public note

    try {
      // Navigate to Notes
      await _browser.navigate('https://substack.com/notes');
      await _browser.wait(2000);

      // Click on compose area
      final snapshot = await _browser.snapshot();
      final composeArea = SnapshotParser.findFirst(
        snapshot,
        role: 'textbox',
      );

      if (composeArea != null) {
        // Personalize message with @mention if handle available
        var noteMessage = message;
        if (profile.handle != null) {
          noteMessage = '@${profile.handle} $message';
        }

        await _browser.typeIntoElement(composeArea, noteMessage);
        await _browser.wait(500);

        // Find and click Post button
        final postSnapshot = await _browser.snapshot();
        final postButton = SnapshotParser.findByText(postSnapshot, 'Post');

        if (postButton != null) {
          await _browser.clickElement(postButton);
          await _browser.wait(1000);
          debugPrint('Posted note to ${profile.name} on Substack');
        }
      }
    } catch (e) {
      debugPrint('Error sending Substack note: $e');
      rethrow;
    }
  }

  /// Comment on the latest post of a publication
  Future<void> commentOnLatestPost(
    ProfileData profile,
    String comment,
  ) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    if (profile.profileUrl == null) {
      throw ArgumentError('Profile URL is required');
    }

    try {
      // Navigate to publication
      await _browser.navigate(profile.profileUrl!);
      await _browser.wait(2000);

      // Find the latest post link
      final snapshot = await _browser.snapshot();
      final postLinks = SnapshotParser.findAll(
        snapshot,
        role: 'link',
        predicate: (element) {
          final href = element.getAttribute('href') ?? '';
          return href.contains('/p/'); // Post URLs contain /p/
        },
      );

      if (postLinks.isNotEmpty) {
        // Click on first (latest) post
        await _browser.clickElement(postLinks.first);
        await _browser.wait(2000);

        // Scroll to comments section
        await _browser.scroll(direction: 'down');
        await _browser.wait(1000);

        // Find comment input
        final commentSnapshot = await _browser.snapshot();
        final commentInput = SnapshotParser.findFirst(
          commentSnapshot,
          role: 'textbox',
        );

        if (commentInput != null) {
          await _browser.typeIntoElement(commentInput, comment);
          await _browser.wait(500);

          // Find and click submit/post button
          final submitSnapshot = await _browser.snapshot();
          final submitButton =
              SnapshotParser.findByText(submitSnapshot, 'Post') ??
                  SnapshotParser.findByText(submitSnapshot, 'Reply');

          if (submitButton != null) {
            await _browser.clickElement(submitButton);
            await _browser.wait(1000);
            debugPrint('Commented on ${profile.name}\'s post');
          }
        }
      }
    } catch (e) {
      debugPrint('Error commenting on Substack post: $e');
      rethrow;
    }
  }

  /// Post a note (short-form post) on Substack
  ///
  /// This is a broadcast action that doesn't target a specific profile.
  Future<void> postNote(String content) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    try {
      // Navigate to Notes
      await _browser.navigate('https://substack.com/notes');
      await _browser.wait(2000);

      // Click on compose area
      final snapshot = await _browser.snapshot();
      final composeArea = SnapshotParser.findFirst(
        snapshot,
        role: 'textbox',
      );

      if (composeArea == null) {
        throw Exception('Note compose area not found');
      }

      await _browser.clickElement(composeArea);
      await _browser.wait(500);

      await _browser.typeIntoElement(composeArea, content);
      await _browser.wait(500);

      // Find and click Post button
      final postSnapshot = await _browser.snapshot();
      final postButton = SnapshotParser.findByText(postSnapshot, 'Post');

      if (postButton == null) {
        throw Exception('Post button not found');
      }

      await _browser.clickElement(postButton);
      await _browser.wait(1000);

      debugPrint(
          '✓ Posted note on Substack: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
    } catch (e) {
      throw Exception('Failed to post Substack note: $e');
    }
  }

  @override
  Future<void> cleanup() async {
    await _browser.cleanup();
    _initialized = false;
  }
}

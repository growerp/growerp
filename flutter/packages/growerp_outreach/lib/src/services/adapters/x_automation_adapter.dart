import '../platform_automation_adapter.dart';
import '../browser_mcp_service.dart';
import '../element_selector.dart';
import '../../utils/logger.dart';
import '../../utils/rate_limiter.dart';

/// X (formerly Twitter) automation adapter using browsermcp
///
/// This adapter uses the browsermcp MCP server to automate X
/// profile searches, follows, and direct messages.
class XAutomationAdapter with LoggerMixin implements PlatformAutomationAdapter {
  final BrowserMCPService _browser = BrowserMCPService();
  final RateLimiter _rateLimiter = PlatformRateLimiters.twitter;
  bool _initialized = false;

  @override
  String get platformName => 'TWITTER';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await _browser.initialize();

    // Navigate to Twitter/X
    await _browser.navigate('https://twitter.com');

    // Wait for page load
    await _browser.wait(2.0);

    _initialized = true;
  }

  @override
  Future<bool> isLoggedIn() async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    try {
      // Take snapshot and check for logged-in indicators
      await _browser.snapshot();
      final selector = _browser.selector;

      if (selector == null) return false;

      // Check if we can see the home timeline or profile elements
      // Look for Tweet compose button or profile navigation
      final tweetButton = selector.byTestId('tweetButton');
      final homeTimeline = selector.byText('Home');

      // If we can find these elements, we're logged in
      return tweetButton != null || homeTimeline != null;
    } catch (e) {
      logger.warning('Error checking Twitter login status: $e');
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
      await _browser.wait(2.0);

      // Take snapshot to get search results
      await _browser.snapshot();

      // Parse snapshot to extract profile data
      // In production, iterate through snapshot['elements'] to find:
      // - Profile cards (typically have data-testid="UserCell")
      // - Extract name, handle, bio, etc.

      // Example profile extraction (mock for now)
      // In production, this would parse actual snapshot data:
      // final elements = snapshot['elements'] as List? ?? [];
      // for (final element in elements) {
      //   Look for user cells and extract data
      //   profiles.add(ProfileData(...));
      // }

      // Mock data for demonstration
      profiles.add(const ProfileData(
        name: 'Example User',
        profileUrl: 'https://twitter.com/exampleuser',
        handle: '@exampleuser',
        company: 'Tech Company',
        title: 'Software Engineer',
      ));
    } catch (e) {
      print('Error searching Twitter profiles: $e');
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
      await _browser.wait(1.5);

      // Take snapshot to find follow button
      await _browser.snapshot();

      // Find and click follow button
      // In production, parse snapshot to find button with:
      // - data-testid="follow" or text "Follow"
      // - Get the element reference

      // Mock click for demonstration
      await _browser.click(
        element: 'Follow button',
        ref: 'follow-button-ref', // Would come from snapshot
      );

      // Wait for action to complete
      await _browser.wait(0.5);

      print('✓ Followed ${profile.handle ?? profile.name} on Twitter');
    } catch (e) {
      throw Exception('Failed to follow Twitter profile: $e');
    }
  }

  @override
  Future<void> sendDirectMessage(ProfileData profile, String message) async {
    if (!_initialized) {
      throw StateError('Adapter not initialized. Call initialize() first.');
    }

    if (profile.profileUrl == null) {
      throw ArgumentError('Profile URL is required for Twitter DM');
    }

    try {
      // Navigate to profile
      await _browser.navigate(profile.profileUrl!);
      await _browser.wait(1.5);

      // Take snapshot to find message button
      await _browser.snapshot();

      // Find and click message button
      // In production, look for data-testid="sendDMFromProfile"
      await _browser.click(
        element: 'Message button',
        ref: 'message-button-ref', // Would come from snapshot
      );

      // Wait for DM dialog to open
      await _browser.wait(1.0);

      // Take new snapshot to find message input
      await _browser.snapshot();

      // Find message input field and type message
      // In production, look for data-testid="dmComposerTextInput"
      await _browser.type(
        element: 'DM text input',
        ref: 'dm-input-ref', // Would come from snapshot
        text: message,
      );

      // Wait a moment for typing to complete
      await _browser.wait(0.3);

      // Find and click send button
      // In production, look for data-testid="dmComposerSendButton"
      await _browser.click(
        element: 'Send button',
        ref: 'send-button-ref', // Would come from snapshot
      );

      // Wait for message to send
      await _browser.wait(0.5);

      print('✓ Sent DM to ${profile.handle ?? profile.name}: $message');
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

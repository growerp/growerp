/// Base interface for all platform automation adapters
///
/// Each platform (Email, LinkedIn, Twitter, etc.) implements this interface
/// to provide consistent automation capabilities across different channels.
abstract class PlatformAutomationAdapter {
  /// Platform name (e.g., 'EMAIL', 'LINKEDIN', 'TWITTER')
  String get platformName;

  /// Initialize the adapter (e.g., connect to SMTP, open browser)
  Future<void> initialize();

  /// Check if user is logged in to the platform
  Future<bool> isLoggedIn();

  /// Search for profiles/contacts based on criteria
  Future<List<ProfileData>> searchProfiles(String criteria);

  /// Send connection request or follow (for social platforms)
  Future<void> sendConnectionRequest(ProfileData profile, String message);

  /// Send direct message to a profile
  /// For email: [campaignId] and [subject] are required
  Future<void> sendDirectMessage(
    ProfileData profile,
    String message, {
    String? campaignId,
    String? subject,
  });

  /// Cleanup resources (e.g., close browser, disconnect)
  Future<void> cleanup();
}

/// Profile data extracted from platform
class ProfileData {
  final String name;
  final String? profileUrl;
  final String? handle;
  final String? email;
  final String? company;
  final String? title;

  const ProfileData({
    required this.name,
    this.profileUrl,
    this.handle,
    this.email,
    this.company,
    this.title,
  });
}

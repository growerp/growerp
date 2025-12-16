import 'package:growerp_models/growerp_models.dart';
import '../platform_automation_adapter.dart';

/// Email automation adapter using Moqui's email services
///
/// This adapter sends emails via Moqui's built-in email functionality
/// through the REST API. No direct SMTP configuration needed in Flutter.
/// The backend handles:
/// - SMTP sending via configured email server
/// - Adding unsubscribe link automatically
/// - Recording the message in OutreachMessage entity
/// - Updating campaign metrics (messages sent count)
class EmailAutomationAdapter implements PlatformAutomationAdapter {
  EmailAutomationAdapter(this.restClient);

  final RestClient restClient;

  @override
  String get platformName => 'EMAIL';

  @override
  Future<void> initialize() async {
    // No initialization needed - Moqui handles email configuration
  }

  @override
  Future<bool> isLoggedIn() async {
    // For email, always return true if user is authenticated
    // Email configuration is handled by Moqui backend
    return true;
  }

  @override
  Future<List<ProfileData>> searchProfiles(String criteria) async {
    // For email, profiles come from leads in the system
    // The criteria can be used to filter by tags or attributes
    // For now, return empty - caller should provide profiles directly
    return [];
  }

  @override
  Future<void> sendConnectionRequest(
    ProfileData profile,
    String message,
  ) async {
    // Not applicable for email
    throw UnsupportedError('Email does not support connection requests');
  }

  @override
  Future<void> sendDirectMessage(
    ProfileData profile,
    String message, {
    String? campaignId,
    String? subject,
  }) async {
    if (profile.email == null || profile.email!.isEmpty) {
      throw ArgumentError('Profile must have an email address');
    }
    if (campaignId == null) {
      throw ArgumentError('Campaign ID is required for email');
    }
    if (subject == null || subject.isEmpty) {
      throw ArgumentError('Email subject is required');
    }

    // Send email via Moqui backend service
    await restClient.sendOutreachEmail(
      marketingCampaignId: campaignId,
      toEmail: profile.email!,
      toName: profile.name,
      subject: subject,
      body: message,
      bodyContentType: 'text/html',
    );
  }

  @override
  Future<void> cleanup() async {
    // No cleanup needed for email
  }
}

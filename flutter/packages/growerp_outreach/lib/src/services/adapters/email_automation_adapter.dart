import 'package:growerp_models/growerp_models.dart';
import '../platform_automation_adapter.dart';

/// Email automation adapter using Moqui's email services
///
/// This adapter sends emails via Moqui's built-in email functionality
/// through the REST API. No direct SMTP configuration needed in Flutter.
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
    // For email, profiles would be loaded from CSV or database
    // This is a placeholder - actual implementation would parse CSV
    // or fetch from a contact list
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
  Future<void> sendDirectMessage(ProfileData profile, String message) async {
    if (profile.email == null || profile.email!.isEmpty) {
      throw ArgumentError('Profile must have an email address');
    }

    // TODO: Create a new Moqui service endpoint for sending outreach emails
    // The service should:
    // 1. Use Moqui's EmailServices to send the email
    // 2. Add unsubscribe link automatically
    // 3. Track email opens/clicks if configured
    // 4. Record the message via create#OutreachMessage
    //
    // Example service call:
    // await restClient.sendOutreachEmail(
    //   toEmail: profile.email!,
    //   toName: profile.name,
    //   subject: emailSubject,
    //   body: message,
    //   campaignId: campaignId,
    // );

    throw UnimplementedError(
      'Email sending via Moqui email services not yet implemented. '
      'Need to create backend service endpoint.',
    );
  }

  @override
  Future<void> cleanup() async {
    // No cleanup needed for email
  }
}

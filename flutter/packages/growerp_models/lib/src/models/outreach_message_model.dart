import 'package:json_annotation/json_annotation.dart';

part 'outreach_message_model.g.dart';

/// Outreach Message model
@JsonSerializable(explicitToJson: true)
class OutreachMessage {
  /// Message unique identifier
  final String? messageId;

  /// Parent campaign ID (maps to marketingCampaignId in JSON)
  @JsonKey(name: 'marketingCampaignId')
  final String? campaignId;

  /// Platform: EMAIL, LINKEDIN, TWITTER, etc.
  final String platform;

  /// Recipient name
  final String? recipientName;

  /// Platform-specific profile URL
  final String? recipientProfileUrl;

  /// Platform-specific handle (e.g., @username)
  final String? recipientHandle;

  /// Recipient email address
  final String? recipientEmail;

  /// Message content sent
  final String messageContent;

  /// When message was sent
  final DateTime? sentDate;

  /// When response was received
  final DateTime? responseDate;

  /// Message status: PENDING, SENT, RESPONDED, FAILED
  @JsonKey(defaultValue: 'PENDING')
  final String status;

  /// Error message if failed
  final String? errorMessage;

  const OutreachMessage({
    this.messageId,
    this.campaignId,
    required this.platform,
    this.recipientName,
    this.recipientProfileUrl,
    this.recipientHandle,
    this.recipientEmail,
    required this.messageContent,
    this.sentDate,
    this.responseDate,
    required this.status,
    this.errorMessage,
  });

  factory OutreachMessage.fromJson(Map<String, dynamic> json) =>
      _$OutreachMessageFromJson(json);

  Map<String, dynamic> toJson() => _$OutreachMessageToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutreachMessage &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;

  @override
  String toString() => 'OutreachMessage($messageId, $platform, $recipientName)';
}

/// List wrapper for OutreachMessage objects
@JsonSerializable(explicitToJson: true)
class OutreachMessages {
  final List<OutreachMessage> messages;

  const OutreachMessages({required this.messages});

  factory OutreachMessages.fromJson(Map<String, dynamic> json) =>
      _$OutreachMessagesFromJson(json);
  Map<String, dynamic> toJson() => _$OutreachMessagesToJson(this);
}

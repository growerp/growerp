import 'package:json_annotation/json_annotation.dart';
import '../json_converters.dart';

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
  @JsonKey(defaultValue: '')
  final String platform;

  /// Recipient name
  final String? recipientName;

  /// Platform-specific profile URL
  final String? recipientProfileUrl;

  /// Platform-specific handle (e.g., @username)
  final String? recipientHandle;

  /// Recipient email address
  final String? recipientEmail;

  /// Recipient's company name
  final String? recipientCompany;

  /// Recipient's job title
  final String? recipientTitle;

  /// Message content sent
  @JsonKey(defaultValue: '')
  final String messageContent;

  /// Subject override for EMAIL; the campaign's emailSubject is used when empty
  final String? emailSubject;

  /// When message was sent
  @DateTimeConverter()
  final DateTime? sentDate;

  /// When response was received
  @DateTimeConverter()
  final DateTime? responseDate;

  /// When the message was created: the send attempt time for messages which
  /// never got a sentDate (FAILED, still PENDING)
  @DateTimeConverter()
  final DateTime? createdDate;

  /// When the last send attempt ran, successful or not
  @DateTimeConverter()
  final DateTime? lastAttemptDate;

  /// Send attempts so far; the status only becomes FAILED when these run out
  @JsonKey(defaultValue: 0)
  final int attemptCount;

  /// Message status: PENDING, SENT, RESPONDED, FAILED
  @JsonKey(defaultValue: 'PENDING')
  final String status;

  /// Error message if failed
  final String? errorMessage;

  /// GrowERP partyId of the User(role: lead) created when this prospect was
  /// converted.  Null until status reaches CONVERTED.
  ///
  /// Status lifecycle:
  ///   PENDING    – discovered by scraper, not yet messaged
  ///   SENT       – outreach message delivered
  ///   RESPONDED  – prospect replied / accepted connection
  ///   CONVERTED  – promoted to User(role: lead); see [convertedPartyId]
  ///   FAILED     – send / scrape error
  final String? convertedPartyId;

  const OutreachMessage({
    this.messageId,
    this.campaignId,
    required this.platform,
    this.recipientName,
    this.recipientProfileUrl,
    this.recipientHandle,
    this.recipientEmail,
    this.recipientCompany,
    this.recipientTitle,
    required this.messageContent,
    this.emailSubject,
    this.sentDate,
    this.responseDate,
    this.createdDate,
    this.lastAttemptDate,
    this.attemptCount = 0,
    required this.status,
    this.errorMessage,
    this.convertedPartyId,
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

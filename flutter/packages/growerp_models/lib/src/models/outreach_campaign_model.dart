import 'package:json_annotation/json_annotation.dart';
import '../json_converters.dart';

part 'outreach_campaign_model.g.dart';

/// Outreach Campaign model
@JsonSerializable(explicitToJson: true)
class OutreachCampaign {
  /// System-wide unique identifier
  final String? campaignId;

  /// User-friendly identifier
  final String? pseudoId;

  /// Owner party ID
  final String? ownerPartyId;

  /// Campaign name
  final String name;

  /// JSON array of platforms (EMAIL, LINKEDIN, TWITTER, etc.)
  final String platforms;

  /// Target audience description
  final String? targetAudience;

  /// Associated landing page ID
  final String? landingPageId;

  /// Message template with personalization tokens
  final String? messageTemplate;

  /// Email subject line (for EMAIL platform)
  final String? emailSubject;

  /// Campaign status: DRAFT, ACTIVE, PAUSED, COMPLETED
  @JsonKey(defaultValue: 'DRAFT')
  final String status;

  /// Max messages per day per platform
  final int dailyLimitPerPlatform;

  /// Messages sent count
  final int messagesSent;

  /// Responses received count
  final int responsesReceived;

  /// Leads generated count
  final int leadsGenerated;

  /// Created timestamp
  @DateTimeConverter()
  final DateTime? createdDate;

  /// Last modified timestamp
  @DateTimeConverter()
  final DateTime? lastModifiedDate;

  const OutreachCampaign({
    this.campaignId,
    this.pseudoId,
    this.ownerPartyId,
    required this.name,
    required this.platforms,
    this.targetAudience,
    this.landingPageId,
    this.messageTemplate,
    this.emailSubject,
    required this.status,
    this.dailyLimitPerPlatform = 50,
    this.messagesSent = 0,
    this.responsesReceived = 0,
    this.leadsGenerated = 0,
    this.createdDate,
    this.lastModifiedDate,
  });

  /// Creates a copy with optionally replaced fields
  OutreachCampaign copyWith({
    String? campaignId,
    String? pseudoId,
    String? ownerPartyId,
    String? name,
    String? platforms,
    String? targetAudience,
    String? landingPageId,
    String? messageTemplate,
    String? emailSubject,
    String? status,
    int? dailyLimitPerPlatform,
    int? messagesSent,
    int? responsesReceived,
    int? leadsGenerated,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) {
    return OutreachCampaign(
      campaignId: campaignId ?? this.campaignId,
      pseudoId: pseudoId ?? this.pseudoId,
      ownerPartyId: ownerPartyId ?? this.ownerPartyId,
      name: name ?? this.name,
      platforms: platforms ?? this.platforms,
      targetAudience: targetAudience ?? this.targetAudience,
      landingPageId: landingPageId ?? this.landingPageId,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      emailSubject: emailSubject ?? this.emailSubject,
      status: status ?? this.status,
      dailyLimitPerPlatform:
          dailyLimitPerPlatform ?? this.dailyLimitPerPlatform,
      messagesSent: messagesSent ?? this.messagesSent,
      responsesReceived: responsesReceived ?? this.responsesReceived,
      leadsGenerated: leadsGenerated ?? this.leadsGenerated,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  factory OutreachCampaign.fromJson(Map<String, dynamic> json) =>
      _$OutreachCampaignFromJson(json['campaign'] ?? json);

  Map<String, dynamic> toJson() => _$OutreachCampaignToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutreachCampaign &&
          runtimeType == other.runtimeType &&
          campaignId == other.campaignId;

  @override
  int get hashCode => campaignId.hashCode;

  @override
  String toString() => 'OutreachCampaign($campaignId, $name)';
}

/// List wrapper for OutreachCampaign objects
@JsonSerializable(explicitToJson: true)
class OutreachCampaigns {
  final List<OutreachCampaign> campaigns;

  const OutreachCampaigns({required this.campaigns});

  factory OutreachCampaigns.fromJson(Map<String, dynamic> json) =>
      _$OutreachCampaignsFromJson(json);
  Map<String, dynamic> toJson() => _$OutreachCampaignsToJson(this);
}

import 'package:json_annotation/json_annotation.dart';
import '../json_converters.dart';

part 'outreach_campaign_model.g.dart';

/// Outreach Campaign model - wraps MarketingCampaign entity
@JsonSerializable(explicitToJson: true)
class OutreachCampaign {
  /// System-wide unique identifier (maps to marketingCampaignId)
  @JsonKey(name: 'marketingCampaignId')
  final String? campaignId;

  /// User-friendly identifier
  final String? pseudoId;

  /// Owner party ID
  final String? ownerPartyId;

  /// Campaign name (maps to campaignName)
  @JsonKey(name: 'campaignName')
  final String name;

  /// Campaign summary/description
  @JsonKey(name: 'campaignSummary')
  final String? description;

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

  /// Campaign status: MKTG_CAMP_PLANNED, MKTG_CAMP_APPROVED, MKTG_CAMP_INPROGRESS, etc.
  @JsonKey(name: 'statusId', defaultValue: 'MKTG_CAMP_PLANNED')
  final String status;

  /// Max messages per day per platform
  @JsonKey(defaultValue: 50)
  final int dailyLimitPerPlatform;

  /// Budgeted cost for the campaign (stored as String to handle BigDecimal)
  final String? budgetedCost;

  /// Actual cost incurred (stored as String to handle BigDecimal)
  final String? actualCost;

  /// Estimated cost (stored as String to handle BigDecimal)
  final String? estimatedCost;

  /// Expected revenue from the campaign (stored as String to handle BigDecimal)
  final String? expectedRevenue;

  /// Expected response percentage (stored as String to handle BigDecimal)
  final String? expectedResponsePercent;

  /// Number of messages/emails sent
  @JsonKey(defaultValue: 0)
  final int numSent;

  /// Number of converted leads
  final String? convertedLeads;

  /// Whether the campaign is active
  @JsonKey(defaultValue: 'N')
  final String? isActive;

  /// Messages sent count (from metrics)
  @JsonKey(defaultValue: 0)
  final int messagesSent;

  /// Responses received count (from metrics)
  @JsonKey(defaultValue: 0)
  final int responsesReceived;

  /// Leads generated count (from metrics)
  @JsonKey(defaultValue: 0)
  final int leadsGenerated;

  /// Campaign start date (fromDate in backend)
  @JsonKey(name: 'fromDate')
  @DateTimeConverter()
  final DateTime? createdDate;

  /// Campaign end date
  @DateTimeConverter()
  final DateTime? thruDate;

  /// Campaign automation start date
  @DateTimeConverter()
  final DateTime? startDate;

  const OutreachCampaign({
    this.campaignId,
    this.pseudoId,
    this.ownerPartyId,
    required this.name,
    this.description,
    required this.platforms,
    this.targetAudience,
    this.landingPageId,
    this.messageTemplate,
    this.emailSubject,
    required this.status,
    this.dailyLimitPerPlatform = 50,
    this.budgetedCost,
    this.actualCost,
    this.estimatedCost,
    this.expectedRevenue,
    this.expectedResponsePercent,
    this.numSent = 0,
    this.convertedLeads,
    this.isActive,
    this.messagesSent = 0,
    this.responsesReceived = 0,
    this.leadsGenerated = 0,
    this.createdDate,
    this.thruDate,
    this.startDate,
  });

  /// Creates a copy with optionally replaced fields
  OutreachCampaign copyWith({
    String? campaignId,
    String? pseudoId,
    String? ownerPartyId,
    String? name,
    String? description,
    String? platforms,
    String? targetAudience,
    String? landingPageId,
    String? messageTemplate,
    String? emailSubject,
    String? status,
    int? dailyLimitPerPlatform,
    String? budgetedCost,
    String? actualCost,
    String? estimatedCost,
    String? expectedRevenue,
    String? expectedResponsePercent,
    int? numSent,
    String? convertedLeads,
    String? isActive,
    int? messagesSent,
    int? responsesReceived,
    int? leadsGenerated,
    DateTime? createdDate,
    DateTime? thruDate,
    DateTime? startDate,
  }) {
    return OutreachCampaign(
      campaignId: campaignId ?? this.campaignId,
      pseudoId: pseudoId ?? this.pseudoId,
      ownerPartyId: ownerPartyId ?? this.ownerPartyId,
      name: name ?? this.name,
      description: description ?? this.description,
      platforms: platforms ?? this.platforms,
      targetAudience: targetAudience ?? this.targetAudience,
      landingPageId: landingPageId ?? this.landingPageId,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      emailSubject: emailSubject ?? this.emailSubject,
      status: status ?? this.status,
      dailyLimitPerPlatform:
          dailyLimitPerPlatform ?? this.dailyLimitPerPlatform,
      budgetedCost: budgetedCost ?? this.budgetedCost,
      actualCost: actualCost ?? this.actualCost,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      expectedRevenue: expectedRevenue ?? this.expectedRevenue,
      expectedResponsePercent:
          expectedResponsePercent ?? this.expectedResponsePercent,
      numSent: numSent ?? this.numSent,
      convertedLeads: convertedLeads ?? this.convertedLeads,
      isActive: isActive ?? this.isActive,
      messagesSent: messagesSent ?? this.messagesSent,
      responsesReceived: responsesReceived ?? this.responsesReceived,
      leadsGenerated: leadsGenerated ?? this.leadsGenerated,
      createdDate: createdDate ?? this.createdDate,
      thruDate: thruDate ?? this.thruDate,
      startDate: startDate ?? this.startDate,
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

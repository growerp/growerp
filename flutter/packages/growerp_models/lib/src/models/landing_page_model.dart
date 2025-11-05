import 'package:json_annotation/json_annotation.dart';

part 'landing_page_model.g.dart';

/// Converts nullable Unix timestamp (milliseconds) to nullable DateTime
class NullableTimestampConverter implements JsonConverter<DateTime?, int?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(int? timestamp) =>
      timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  @override
  int? toJson(DateTime? dateTime) => dateTime?.millisecondsSinceEpoch;
}

/// Landing Page model representing a single landing page
///
/// Supports dual-ID strategy:
/// - pageId: System-wide unique identifier
/// - pseudoId: Tenant-unique, user-facing identifier
///
/// When fetched via get#LandingPage service, includes nested sections, credibility, and CTA
@JsonSerializable(explicitToJson: true)
class LandingPage {
  /// System-wide unique identifier
  @JsonKey(defaultValue: 'unknown')
  final String? landingPageId;

  /// Tenant-unique identifier (user-facing, used in URLs)
  @JsonKey(defaultValue: 'unknown')
  final String? pseudoId;

  /// Landing page title
  @JsonKey(defaultValue: 'Unnamed Page')
  final String title;

  /// Hook type: frustration, results, custom
  final String? hookType;

  /// Main headline for hero section
  final String? headline;

  /// Optional subheading
  final String? subheading;

  /// Privacy policy URL
  final String? privacyPolicyUrl;

  /// CTA action type: 'assessment' or 'url'
  final String? ctaActionType;

  /// CTA assessment ID (when ctaActionType is 'assessment')
  final String? ctaAssessmentId;

  /// CTA button link/URL (when ctaActionType is 'url')
  final String? ctaButtonLink;

  /// Landing page status: ACTIVE, INACTIVE, DRAFT
  @JsonKey(defaultValue: 'DRAFT')
  final String status;

  /// Timestamp when created
  @NullableTimestampConverter()
  final DateTime? createdDate;

  /// Username who created this landing page
  final String? createdByUserLogin;

  /// Timestamp when last modified
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;

  /// Username who last modified this landing page
  final String? lastModifiedByUserLogin;

  /// Page sections (only present when fetched via get#LandingPage)
  final List<LandingPageSection>? sections;

  /// Credibility info (only present when fetched via get#LandingPage)
  final CredibilityInfo? credibility;

  const LandingPage({
    this.landingPageId,
    this.pseudoId,
    required this.title,
    this.hookType,
    this.headline,
    this.subheading,
    this.privacyPolicyUrl,
    this.ctaActionType,
    this.ctaAssessmentId,
    this.ctaButtonLink,
    required this.status,
    this.createdDate,
    this.createdByUserLogin,
    this.lastModifiedDate,
    this.lastModifiedByUserLogin,
    this.sections,
    this.credibility,
  });

  /// Creates a copy of this landing page with optionally replaced fields
  LandingPage copyWith({
    String? landingPageId,
    String? pseudoId,
    String? title,
    String? hookType,
    String? headline,
    String? subheading,
    String? privacyPolicyUrl,
    String? ctaActionType,
    String? ctaAssessmentId,
    String? ctaButtonLink,
    String? status,
    DateTime? createdDate,
    String? createdByUserLogin,
    DateTime? lastModifiedDate,
    String? lastModifiedByUserLogin,
    List<LandingPageSection>? sections,
    CredibilityInfo? credibility,
  }) {
    return LandingPage(
      landingPageId: landingPageId ?? this.landingPageId,
      pseudoId: pseudoId ?? this.pseudoId,
      title: title ?? this.title,
      hookType: hookType ?? this.hookType,
      headline: headline ?? this.headline,
      subheading: subheading ?? this.subheading,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      ctaActionType: ctaActionType ?? this.ctaActionType,
      ctaAssessmentId: ctaAssessmentId ?? this.ctaAssessmentId,
      ctaButtonLink: ctaButtonLink ?? this.ctaButtonLink,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      createdByUserLogin: createdByUserLogin ?? this.createdByUserLogin,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      lastModifiedByUserLogin:
          lastModifiedByUserLogin ?? this.lastModifiedByUserLogin,
      sections: sections ?? this.sections,
      credibility: credibility ?? this.credibility,
    );
  }

  /// Converts JSON to LandingPage object
  factory LandingPage.fromJson(Map<String, dynamic> json) =>
      _$LandingPageFromJson(json['landingPage'] ?? json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandingPage &&
          runtimeType == other.runtimeType &&
          landingPageId == other.landingPageId;

  @override
  int get hashCode => landingPageId.hashCode;
}

/// List wrapper for LandingPage objects
@JsonSerializable()
class LandingPages {
  final List<LandingPage> landingPages;

  const LandingPages({required this.landingPages});

  factory LandingPages.fromJson(Map<String, dynamic> json) =>
      _$LandingPagesFromJson(json);
  Map<String, dynamic> toJson() => _$LandingPagesToJson(this);
}

/// Landing Page Section model
@JsonSerializable(explicitToJson: true)
class LandingPageSection {
  /// Section unique identifier
  final String? landingPageSectionId;

  /// Tenant-unique identifier for section
  final String? pseudoId;

  /// Section title
  final String? sectionTitle;

  /// Section description/content
  final String? sectionDescription;

  /// Section image URL
  final String? sectionImageUrl;

  /// Display order/sequence
  final int? sectionSequence;

  const LandingPageSection({
    this.landingPageSectionId,
    this.pseudoId,
    this.sectionTitle,
    this.sectionDescription,
    this.sectionImageUrl,
    this.sectionSequence,
  });

  factory LandingPageSection.fromJson(Map<String, dynamic> json) =>
      _$LandingPageSectionFromJson(json);

  Map<String, dynamic> toJson() => _$LandingPageSectionToJson(this);

  @override
  String toString() =>
      'LandingPageSection($landingPageSectionId, $sectionTitle)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandingPageSection &&
          runtimeType == other.runtimeType &&
          landingPageSectionId == other.landingPageSectionId;

  @override
  int get hashCode => landingPageSectionId.hashCode;
}

/// Credibility Info model
@JsonSerializable(explicitToJson: true)
class CredibilityInfo {
  /// Credibility info unique identifier
  final String? credibilityInfoId;

  /// Tenant-unique identifier for credibility
  final String? pseudoId;

  /// Creator bio/description
  final String? creatorBio;

  /// Background/experience text
  final String? backgroundText;

  /// Creator image URL
  final String? creatorImageUrl;

  /// List of credibility statistics
  final List<CredibilityStatistic>? statistics;

  const CredibilityInfo({
    this.credibilityInfoId,
    this.pseudoId,
    this.creatorBio,
    this.backgroundText,
    this.creatorImageUrl,
    this.statistics,
  });

  factory CredibilityInfo.fromJson(Map<String, dynamic> json) =>
      _$CredibilityInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CredibilityInfoToJson(this);

  @override
  String toString() => 'CredibilityInfo($credibilityInfoId, $creatorBio)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CredibilityInfo &&
          runtimeType == other.runtimeType &&
          credibilityInfoId == other.credibilityInfoId;

  @override
  int get hashCode => credibilityInfoId.hashCode;
}

/// Credibility Statistic model (supporting data points)
@JsonSerializable()
class CredibilityStatistic {
  /// Statistic unique identifier
  final String? credibilityStatisticId;

  /// Tenant-unique identifier for statistic
  final String? pseudoId;

  /// Statistic text (e.g., "100+ customers")
  final String? statistic;

  /// Display sequence/order
  final int? sequence;

  const CredibilityStatistic({
    this.credibilityStatisticId,
    this.pseudoId,
    this.statistic,
    this.sequence,
  });

  factory CredibilityStatistic.fromJson(Map<String, dynamic> json) =>
      _$CredibilityStatisticFromJson(json);

  Map<String, dynamic> toJson() => _$CredibilityStatisticToJson(this);

  @override
  String toString() =>
      'CredibilityStatistic($credibilityStatisticId, $statistic)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CredibilityStatistic &&
          runtimeType == other.runtimeType &&
          credibilityStatisticId == other.credibilityStatisticId;

  @override
  int get hashCode => credibilityStatisticId.hashCode;
}

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
  final String pageId;

  /// Tenant-unique identifier (user-facing, used in URLs)
  @JsonKey(defaultValue: 'unknown')
  final String pseudoId;

  /// Landing page title
  @JsonKey(defaultValue: 'Unnamed Page')
  final String title;

  /// Hook type: frustration, results, custom
  final String? hookType;

  /// Main headline for hero section
  final String? headline;

  /// Optional subheading
  final String? subheading;

  /// Associated assessment ID
  final String? assessmentId;

  /// Privacy policy URL
  final String? privacyPolicyUrl;

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
  final CredibilityElement? credibility;

  /// Primary call-to-action (only present when fetched via get#LandingPage)
  final CallToAction? cta;

  const LandingPage({
    required this.pageId,
    required this.pseudoId,
    required this.title,
    this.hookType,
    this.headline,
    this.subheading,
    this.assessmentId,
    this.privacyPolicyUrl,
    required this.status,
    this.createdDate,
    this.createdByUserLogin,
    this.lastModifiedDate,
    this.lastModifiedByUserLogin,
    this.sections,
    this.credibility,
    this.cta,
  });

  /// Creates a copy of this landing page with optionally replaced fields
  LandingPage copyWith({
    String? pageId,
    String? pseudoId,
    String? title,
    String? hookType,
    String? headline,
    String? subheading,
    String? assessmentId,
    String? privacyPolicyUrl,
    String? status,
    DateTime? createdDate,
    String? createdByUserLogin,
    DateTime? lastModifiedDate,
    String? lastModifiedByUserLogin,
    List<LandingPageSection>? sections,
    CredibilityElement? credibility,
    CallToAction? cta,
  }) {
    return LandingPage(
      pageId: pageId ?? this.pageId,
      pseudoId: pseudoId ?? this.pseudoId,
      title: title ?? this.title,
      hookType: hookType ?? this.hookType,
      headline: headline ?? this.headline,
      subheading: subheading ?? this.subheading,
      assessmentId: assessmentId ?? this.assessmentId,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      createdByUserLogin: createdByUserLogin ?? this.createdByUserLogin,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      lastModifiedByUserLogin:
          lastModifiedByUserLogin ?? this.lastModifiedByUserLogin,
      sections: sections ?? this.sections,
      credibility: credibility ?? this.credibility,
      cta: cta ?? this.cta,
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
          pageId == other.pageId;

  @override
  int get hashCode => pageId.hashCode;
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
  final String? sectionId;

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
    this.sectionId,
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
  String toString() => 'LandingPageSection($sectionId, $sectionTitle)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandingPageSection &&
          runtimeType == other.runtimeType &&
          sectionId == other.sectionId;

  @override
  int get hashCode => sectionId.hashCode;
}

/// Credibility Element model
@JsonSerializable(explicitToJson: true)
class CredibilityElement {
  /// Credibility unique identifier
  final String? credibilityId;

  /// Tenant-unique identifier for credibility
  final String? pseudoId;

  /// Creator bio text
  final String? creatorBio;

  /// Background/experience text
  final String? backgroundText;

  /// Creator image URL
  final String? creatorImageUrl;

  const CredibilityElement({
    this.credibilityId,
    this.pseudoId,
    this.creatorBio,
    this.backgroundText,
    this.creatorImageUrl,
  });

  factory CredibilityElement.fromJson(Map<String, dynamic> json) =>
      _$CredibilityElementFromJson(json);

  Map<String, dynamic> toJson() => _$CredibilityElementToJson(this);

  @override
  String toString() => 'CredibilityElement($credibilityId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CredibilityElement &&
          runtimeType == other.runtimeType &&
          credibilityId == other.credibilityId;

  @override
  int get hashCode => credibilityId.hashCode;
}

/// Call To Action model
@JsonSerializable(explicitToJson: true)
class CallToAction {
  /// CTA unique identifier
  final String? ctaId;

  /// Tenant-unique identifier for CTA
  final String? pseudoId;

  /// Button text
  final String? buttonText;

  /// Estimated time to complete
  final String? estimatedTime;

  /// Cost (e.g., "Free")
  final String? cost;

  /// Value promise text
  final String? valuePromise;

  const CallToAction({
    this.ctaId,
    this.pseudoId,
    this.buttonText,
    this.estimatedTime,
    this.cost,
    this.valuePromise,
  });

  factory CallToAction.fromJson(Map<String, dynamic> json) =>
      _$CallToActionFromJson(json);

  Map<String, dynamic> toJson() => _$CallToActionToJson(this);

  @override
  String toString() => 'CallToAction($ctaId, $buttonText)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallToAction &&
          runtimeType == other.runtimeType &&
          ctaId == other.ctaId;

  @override
  int get hashCode => ctaId.hashCode;
}

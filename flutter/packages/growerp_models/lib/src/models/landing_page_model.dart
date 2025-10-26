import 'package:json_annotation/json_annotation.dart';
import 'assessment_model.dart';

part 'landing_page_model.g.dart';

/// Wrapper response for single landing page fetch from backend
/// Backend returns: { "page": {...}, "sections": [...], "credibility": {...}, "cta": {...} }
@JsonSerializable()
class LandingPageResponse {
  /// The main landing page object
  final LandingPage page;

  /// Page sections (content blocks)
  final List<LandingPageSection>? sections;

  /// Credibility elements (testimonials, logos, etc.)
  final dynamic credibility;

  /// Call-to-action configuration
  final dynamic cta;

  const LandingPageResponse({
    required this.page,
    this.sections,
    this.credibility,
    this.cta,
  });

  factory LandingPageResponse.fromJson(Map<String, dynamic> json) =>
      _$LandingPageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LandingPageResponseToJson(this);
}

/// Landing page model representing a configurable landing page
///
/// Supports dual-ID strategy:
/// - pageId: System-wide unique identifier
/// - pseudoId: Tenant-unique, user-facing identifier (used in URLs)
@JsonSerializable()
class LandingPage {
  /// System-wide unique identifier
  final String pageId;

  /// Tenant-unique identifier (user-facing, used in URLs)
  final String pseudoId;

  /// Page title (SEO and display)
  final String title;

  /// Hero headline (main attention-grabbing text)
  final String headline;

  /// Hook type: frustration, aspiration, curiosity
  final String? hookType;

  /// Subheading (supporting text under headline)
  final String? subheading;

  /// Page description (SEO meta description)
  final String? description;

  /// Hero image URL
  final String? heroImageUrl;

  /// Background color or theme
  final String? backgroundColor;

  /// Text color theme
  final String? textColor;

  /// Page status: ACTIVE, INACTIVE, DRAFT
  final String status;

  /// Associated assessment ID for lead capture flow
  final String? assessmentId;

  /// Page sections (content blocks)
  final List<LandingPageSection>? sections;

  /// Credibility elements (testimonials, logos, etc.)
  @JsonKey(name: 'credibility')
  final List<CredibilityElement>? credibilityElements;

  /// Call-to-action configuration
  @JsonKey(name: 'cta')
  final CallToAction? callToAction;

  /// Creation timestamp
  @JsonKey(name: 'createdDate')
  @NullableTimestampConverter()
  final DateTime? createdDate;

  /// Last update timestamp
  @JsonKey(name: 'lastModifiedDate')
  @NullableTimestampConverter()
  final DateTime? lastUpdated;

  const LandingPage({
    required this.pageId,
    required this.pseudoId,
    required this.title,
    required this.headline,
    this.hookType,
    this.subheading,
    this.description,
    this.heroImageUrl,
    this.backgroundColor,
    this.textColor,
    this.status = 'ACTIVE',
    this.assessmentId,
    this.sections,
    this.credibilityElements,
    this.callToAction,
    this.createdDate,
    this.lastUpdated,
  });

  factory LandingPage.fromJson(Map<String, dynamic> json) =>
      _$LandingPageFromJson(json);

  Map<String, dynamic> toJson() => _$LandingPageToJson(this);

  LandingPage copyWith({
    String? pageId,
    String? pseudoId,
    String? title,
    String? headline,
    String? hookType,
    String? subheading,
    String? description,
    String? heroImageUrl,
    String? backgroundColor,
    String? textColor,
    String? status,
    String? assessmentId,
    List<LandingPageSection>? sections,
    List<CredibilityElement>? credibilityElements,
    CallToAction? callToAction,
    DateTime? createdDate,
    DateTime? lastUpdated,
  }) {
    return LandingPage(
      pageId: pageId ?? this.pageId,
      pseudoId: pseudoId ?? this.pseudoId,
      title: title ?? this.title,
      headline: headline ?? this.headline,
      hookType: hookType ?? this.hookType,
      subheading: subheading ?? this.subheading,
      description: description ?? this.description,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      status: status ?? this.status,
      assessmentId: assessmentId ?? this.assessmentId,
      sections: sections ?? this.sections,
      credibilityElements: credibilityElements ?? this.credibilityElements,
      callToAction: callToAction ?? this.callToAction,
      createdDate: createdDate ?? this.createdDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandingPage &&
          runtimeType == other.runtimeType &&
          pageId == other.pageId &&
          pseudoId == other.pseudoId;

  @override
  int get hashCode => pageId.hashCode ^ pseudoId.hashCode;

  @override
  String toString() =>
      'LandingPage(pageId: $pageId, pseudoId: $pseudoId, title: $title)';
}

/// Response wrapper for landing page list
@JsonSerializable()
class LandingPages {
  final List<LandingPage> landingPages;
  final int? totalResults;
  final int? start;
  final int? limit;

  const LandingPages({
    required this.landingPages,
    this.totalResults,
    this.start,
    this.limit,
  });

  factory LandingPages.fromJson(Map<String, dynamic> json) =>
      _$LandingPagesFromJson(json);

  Map<String, dynamic> toJson() => _$LandingPagesToJson(this);
}

/// Content section within a landing page
@JsonSerializable()
class LandingPageSection {
  /// Section ID
  final String sectionId;

  /// Section pseudo ID
  final String pseudoId;

  /// Section title
  @JsonKey(name: 'sectionTitle')
  final String title;

  /// Section content/description
  @JsonKey(name: 'sectionDescription')
  final String? description;

  /// Section image URL
  @JsonKey(name: 'sectionImageUrl')
  final String? imageUrl;

  /// Display order
  @JsonKey(name: 'sectionSequence')
  final int sequenceNum;

  /// Section type: hero, features, testimonials, etc.
  final String? sectionType;

  const LandingPageSection({
    required this.sectionId,
    required this.pseudoId,
    required this.title,
    this.description,
    this.imageUrl,
    this.sequenceNum = 0,
    this.sectionType,
  });

  factory LandingPageSection.fromJson(Map<String, dynamic> json) =>
      _$LandingPageSectionFromJson(json);

  Map<String, dynamic> toJson() => _$LandingPageSectionToJson(this);

  @override
  String toString() =>
      'LandingPageSection(sectionId: $sectionId, title: $title)';
}

/// Credibility element (testimonial, logo, certification, etc.)
@JsonSerializable()
class CredibilityElement {
  /// Credibility element ID
  final String credibilityId;

  /// Element pseudo ID
  final String pseudoId;

  /// Element type: testimonial, logo, certification, statistic
  final String? elementType;

  /// Element title
  final String? title;

  /// Element content/description
  final String? description;

  /// Associated image URL
  final String? imageUrl;

  /// Author/source name (for testimonials)
  final String? authorName;

  /// Author title/position
  final String? authorTitle;

  /// Company/organization name
  final String? companyName;

  /// Display order
  final int sequenceNum;

  const CredibilityElement({
    required this.credibilityId,
    required this.pseudoId,
    this.elementType,
    this.title,
    this.description,
    this.imageUrl,
    this.authorName,
    this.authorTitle,
    this.companyName,
    this.sequenceNum = 0,
  });

  factory CredibilityElement.fromJson(Map<String, dynamic> json) =>
      _$CredibilityElementFromJson(json);

  Map<String, dynamic> toJson() => _$CredibilityElementToJson(this);

  @override
  String toString() =>
      'CredibilityElement(credibilityId: $credibilityId, type: $elementType)';
}

/// Call-to-action configuration
@JsonSerializable()
class CallToAction {
  /// CTA button text
  final String? buttonText;

  /// CTA action type: assessment, form, external_link, etc.
  final String? actionType;

  /// Target URL or route
  final String? actionTarget;

  /// Button style/theme
  final String? buttonStyle;

  /// Additional CTA text/description
  final String? description;

  const CallToAction({
    this.buttonText,
    this.actionType,
    this.actionTarget,
    this.buttonStyle,
    this.description,
  });

  factory CallToAction.fromJson(Map<String, dynamic> json) =>
      _$CallToActionFromJson(json);

  Map<String, dynamic> toJson() => _$CallToActionToJson(this);

  @override
  String toString() =>
      'CallToAction(buttonText: $buttonText, actionType: $actionType)';
}

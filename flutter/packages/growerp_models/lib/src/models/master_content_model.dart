import 'package:growerp_models/growerp_models.dart';
import 'package:json_annotation/json_annotation.dart';

part 'master_content_model.g.dart';

/// Platform-neutral master content authored once, then adapted per platform
/// into SocialPost (broadcast) or campaign message templates (1:1).
///
/// Supports dual-ID strategy:
/// - masterContentId: System-wide unique identifier
/// - pseudoId: Tenant-unique, user-facing identifier
@JsonSerializable(explicitToJson: true)
class MasterContent {
  /// System-wide unique identifier
  final String? masterContentId;

  /// Tenant-unique identifier (user-facing)
  final String? pseudoId;

  /// Optional link to the weekly PNP ContentPlan
  final String? planId;

  /// Content type: POSTING, ARTICLE or MESSAGE
  @JsonKey(defaultValue: 'POSTING')
  final String contentType;

  /// Pain-News-Prize angle: PAIN, NEWS, PRIZE or OTHER
  @JsonKey(defaultValue: 'OTHER')
  final String pnpType;

  /// Short title/headline
  final String? title;

  /// Canonical platform-neutral body
  final String? body;

  /// One-line call to action
  final String? callToAction;

  /// Optional link (withheld for LinkedIn/DM on adaptation)
  final String? targetUrl;

  /// Status: DRAFT, APPROVED, ADAPTED
  @JsonKey(defaultValue: 'DRAFT')
  final String status;

  /// Timestamp when created
  @NullableTimestampConverter()
  final DateTime? createdDate;

  /// Timestamp when last modified
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;

  const MasterContent({
    this.masterContentId,
    this.pseudoId,
    this.planId,
    required this.contentType,
    required this.pnpType,
    this.title,
    this.body,
    this.callToAction,
    this.targetUrl,
    required this.status,
    this.createdDate,
    this.lastModifiedDate,
  });

  MasterContent copyWith({
    String? masterContentId,
    String? pseudoId,
    String? planId,
    String? contentType,
    String? pnpType,
    String? title,
    String? body,
    String? callToAction,
    String? targetUrl,
    String? status,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) {
    return MasterContent(
      masterContentId: masterContentId ?? this.masterContentId,
      pseudoId: pseudoId ?? this.pseudoId,
      planId: planId ?? this.planId,
      contentType: contentType ?? this.contentType,
      pnpType: pnpType ?? this.pnpType,
      title: title ?? this.title,
      body: body ?? this.body,
      callToAction: callToAction ?? this.callToAction,
      targetUrl: targetUrl ?? this.targetUrl,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  factory MasterContent.fromJson(Map<String, dynamic> json) =>
      _$MasterContentFromJson(json['masterContent'] ?? json);

  Map<String, dynamic> toJson() => _$MasterContentToJson(this);

  @override
  String toString() =>
      'MasterContent(id: $masterContentId, type: $contentType, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasterContent &&
          runtimeType == other.runtimeType &&
          masterContentId == other.masterContentId;

  @override
  int get hashCode => masterContentId.hashCode;
}

/// List wrapper for MasterContent objects
@JsonSerializable()
class MasterContents {
  final List<MasterContent> masterContents;

  const MasterContents({required this.masterContents});

  factory MasterContents.fromJson(Map<String, dynamic> json) =>
      _$MasterContentsFromJson(json);
  Map<String, dynamic> toJson() => _$MasterContentsToJson(this);
}

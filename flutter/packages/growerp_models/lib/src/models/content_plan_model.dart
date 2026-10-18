import 'package:growerp_models/growerp_models.dart';
import 'package:json_annotation/json_annotation.dart';

part 'content_plan_model.g.dart';

/// Content Plan: an outline of PLANNED master content pieces over one or more
/// weeks, Pain-News-Prize or a single posting per week
///
/// Supports dual-ID strategy:
/// - planId: System-wide unique identifier
/// - pseudoId: Tenant-unique, user-facing identifier
@JsonSerializable(explicitToJson: true)
class ContentPlan {
  /// System-wide unique identifier
  final String? planId;

  /// Tenant-unique identifier (user-facing)
  final String? pseudoId;

  /// Associated persona ID
  final String? personaId;

  /// Week start date
  @NullableTimestampConverter()
  final DateTime? weekStartDate;

  /// Number of weeks the plan covers, from [weekStartDate]
  final int? weeks;

  /// PNP (Pain/News/Prize on Mon/Wed/Fri) or SINGLE (one posting on Monday)
  final String? planFormat;

  /// Plan theme
  final String? theme;

  /// Timestamp when created
  @NullableTimestampConverter()
  final DateTime? createdDate;

  /// Timestamp when last modified
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;

  /// Associated social posts (only present when fetched with posts)
  final List<SocialPost>? posts;

  const ContentPlan({
    this.planId,
    this.pseudoId,
    this.personaId,
    this.weekStartDate,
    this.weeks,
    this.planFormat,
    this.theme,
    this.createdDate,
    this.lastModifiedDate,
    this.posts,
  });

  /// Creates a copy of this content plan with optionally replaced fields
  ContentPlan copyWith({
    String? planId,
    String? pseudoId,
    String? personaId,
    DateTime? weekStartDate,
    int? weeks,
    String? planFormat,
    String? theme,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
    List<SocialPost>? posts,
  }) {
    return ContentPlan(
      planId: planId ?? this.planId,
      pseudoId: pseudoId ?? this.pseudoId,
      personaId: personaId ?? this.personaId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weeks: weeks ?? this.weeks,
      planFormat: planFormat ?? this.planFormat,
      theme: theme ?? this.theme,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      posts: posts ?? this.posts,
    );
  }

  /// Converts JSON to ContentPlan object
  factory ContentPlan.fromJson(Map<String, dynamic> json) =>
      _$ContentPlanFromJson(json['contentPlan'] ?? json);

  /// Converts ContentPlan object to JSON
  Map<String, dynamic> toJson() => _$ContentPlanToJson(this);

  @override
  String toString() => 'ContentPlan(id: $planId, theme: $theme)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentPlan &&
          runtimeType == other.runtimeType &&
          planId == other.planId;

  @override
  int get hashCode => planId.hashCode;
}

/// List wrapper for ContentPlan objects
@JsonSerializable()
class ContentPlans {
  final List<ContentPlan> contentPlans;

  const ContentPlans({required this.contentPlans});

  factory ContentPlans.fromJson(Map<String, dynamic> json) =>
      _$ContentPlansFromJson(json);
  Map<String, dynamic> toJson() => _$ContentPlansToJson(this);
}

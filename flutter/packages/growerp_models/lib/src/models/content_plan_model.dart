import 'package:json_annotation/json_annotation.dart';
import 'social_post_model.dart';

part 'content_plan_model.g.dart';

/// Converts Unix timestamp (milliseconds) to DateTime
class TimestampConverter implements JsonConverter<DateTime, int> {
  const TimestampConverter();

  @override
  DateTime fromJson(int timestamp) =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  int toJson(DateTime dateTime) => dateTime.millisecondsSinceEpoch;
}

/// Converts nullable Unix timestamp (milliseconds) to nullable DateTime
class NullableTimestampConverter implements JsonConverter<DateTime?, int?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(int? timestamp) =>
      timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  @override
  int? toJson(DateTime? dateTime) => dateTime?.millisecondsSinceEpoch;
}

/// Content Plan model representing a weekly Pain-News-Prize content strategy
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

  /// Weekly theme
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

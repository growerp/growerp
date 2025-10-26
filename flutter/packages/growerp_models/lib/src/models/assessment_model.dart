import 'package:json_annotation/json_annotation.dart';

part 'assessment_model.g.dart';

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

/// Assessment model representing a single assessment/survey
///
/// Supports dual-ID strategy:
/// - assessmentId: System-wide unique identifier
/// - pseudoId: Tenant-unique, user-facing identifier
@JsonSerializable()
class Assessment {
  /// System-wide unique identifier
  final String assessmentId;

  /// Tenant-unique identifier (user-facing, used in URLs)
  final String pseudoId;

  /// Assessment name/title
  final String assessmentName;

  /// Assessment description/instructions
  final String? description;

  /// Assessment status: ACTIVE, INACTIVE, DRAFT
  final String status;

  /// Timestamp when created
  @TimestampConverter()
  final DateTime createdDate;

  /// Username who created this assessment
  final String? createdByUserLogin;

  /// Timestamp when last modified
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;

  /// Username who last modified this assessment
  final String? lastModifiedByUserLogin;

  const Assessment({
    required this.assessmentId,
    required this.pseudoId,
    required this.assessmentName,
    this.description,
    required this.status,
    required this.createdDate,
    this.createdByUserLogin,
    this.lastModifiedDate,
    this.lastModifiedByUserLogin,
  });

  /// Creates a copy of this assessment with optionally replaced fields
  Assessment copyWith({
    String? assessmentId,
    String? pseudoId,
    String? assessmentName,
    String? description,
    String? status,
    DateTime? createdDate,
    String? createdByUserLogin,
    DateTime? lastModifiedDate,
    String? lastModifiedByUserLogin,
  }) {
    return Assessment(
      assessmentId: assessmentId ?? this.assessmentId,
      pseudoId: pseudoId ?? this.pseudoId,
      assessmentName: assessmentName ?? this.assessmentName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      createdByUserLogin: createdByUserLogin ?? this.createdByUserLogin,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      lastModifiedByUserLogin:
          lastModifiedByUserLogin ?? this.lastModifiedByUserLogin,
    );
  }

  /// Converts JSON to Assessment object
  factory Assessment.fromJson(Map<String, dynamic> json) =>
      _$AssessmentFromJson(json);

  /// Converts Assessment object to JSON
  Map<String, dynamic> toJson() => _$AssessmentToJson(this);

  @override
  String toString() =>
      'Assessment(id: $assessmentId, name: $assessmentName, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Assessment &&
          runtimeType == other.runtimeType &&
          assessmentId == other.assessmentId;

  @override
  int get hashCode => assessmentId.hashCode;
}

/// List wrapper for Assessment objects
@JsonSerializable()
class Assessments {
  final List<Assessment> assessments;

  const Assessments({required this.assessments});

  factory Assessments.fromJson(Map<String, dynamic> json) =>
      _$AssessmentsFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentsToJson(this);
}

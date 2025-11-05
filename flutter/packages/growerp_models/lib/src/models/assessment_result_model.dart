import 'package:json_annotation/json_annotation.dart';

part 'assessment_result_model.g.dart';

/// Assessment result after submission by respondent
@JsonSerializable()
class AssessmentResult {
  /// System-wide unique identifier
  final String assessmentResultId;

  /// Tenant-unique identifier
  final String pseudoId;

  /// Assessment ID that was submitted
  final String assessmentId;

  /// Final score calculated
  final double score;

  /// Resulting lead status/category
  final String leadStatus;

  /// Respondent name
  final String respondentName;

  /// Respondent email
  final String respondentEmail;

  /// Respondent phone number
  final String? respondentPhone;

  /// Respondent company name
  final String? respondentCompany;

  /// JSON encoded answers data
  final String? answersData;

  /// Timestamp when submitted
  final DateTime? createdDate;

  const AssessmentResult({
    required this.assessmentResultId,
    required this.pseudoId,
    required this.assessmentId,
    required this.score,
    required this.leadStatus,
    required this.respondentName,
    required this.respondentEmail,
    this.respondentPhone,
    this.respondentCompany,
    this.answersData,
    this.createdDate,
  });

  AssessmentResult copyWith({
    String? assessmentResultId,
    String? pseudoId,
    String? assessmentId,
    double? score,
    String? leadStatus,
    String? respondentName,
    String? respondentEmail,
    String? respondentPhone,
    String? respondentCompany,
    String? answersData,
    DateTime? createdDate,
  }) {
    return AssessmentResult(
      assessmentResultId: assessmentResultId ?? this.assessmentResultId,
      pseudoId: pseudoId ?? this.pseudoId,
      assessmentId: assessmentId ?? this.assessmentId,
      score: score ?? this.score,
      leadStatus: leadStatus ?? this.leadStatus,
      respondentName: respondentName ?? this.respondentName,
      respondentEmail: respondentEmail ?? this.respondentEmail,
      respondentPhone: respondentPhone ?? this.respondentPhone,
      respondentCompany: respondentCompany ?? this.respondentCompany,
      answersData: answersData ?? this.answersData,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  factory AssessmentResult.fromJson(Map<String, dynamic> json) =>
      _$AssessmentResultFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentResultToJson(this);

  @override
  String toString() =>
      'AssessmentResult(id: $assessmentResultId, score: $score, status: $leadStatus, respondent: $respondentName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentResult &&
          runtimeType == other.runtimeType &&
          assessmentResultId == other.assessmentResultId;

  @override
  int get hashCode => assessmentResultId.hashCode;
}

/// List wrapper for AssessmentResult objects
@JsonSerializable()
class AssessmentResults {
  final List<AssessmentResult> results;

  const AssessmentResults({required this.results});

  factory AssessmentResults.fromJson(Map<String, dynamic> json) =>
      _$AssessmentResultsFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentResultsToJson(this);
}

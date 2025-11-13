import 'package:json_annotation/json_annotation.dart';
import 'assessment_model.dart' show NullableTimestampConverter;

part 'assessment_result_model.g.dart';

/// Enriched answer data with question and option details
@JsonSerializable()
class EnrichedAnswer {
  /// Question ID
  final String? questionId;

  /// Question text
  final String? questionText;

  /// Question sequence number
  final int? questionSequence;

  /// Selected option ID
  final String? optionId;

  /// Selected option text
  final String? optionText;

  /// Score for this option
  final double? optionScore;

  const EnrichedAnswer({
    this.questionId,
    this.questionText,
    this.questionSequence,
    this.optionId,
    this.optionText,
    this.optionScore,
  });

  factory EnrichedAnswer.fromJson(Map<String, dynamic> json) =>
      _$EnrichedAnswerFromJson(json);
  Map<String, dynamic> toJson() => _$EnrichedAnswerToJson(this);

  @override
  String toString() =>
      'EnrichedAnswer(Q$questionSequence: $questionText = $optionText)';
}

/// Assessment result after submission by respondent
@JsonSerializable()
class AssessmentResult {
  /// System-wide unique identifier
  final String? assessmentResultId;

  /// Tenant-unique identifier
  final String? pseudoId;

  /// Assessment ID that was submitted
  final String? assessmentId;

  /// Final score calculated
  final double? score;

  /// Resulting lead status/category
  final String? leadStatus;

  /// Respondent name
  final String? respondentName;

  /// Respondent email
  final String? respondentEmail;

  /// Respondent phone number
  final String? respondentPhone;

  /// Respondent company name
  final String? respondentCompany;

  /// Enriched answers data with question and option text
  final List<EnrichedAnswer>? answersData;

  /// Timestamp when submitted
  @NullableTimestampConverter()
  final DateTime? createdDate;

  const AssessmentResult({
    this.assessmentResultId,
    this.pseudoId,
    this.assessmentId,
    this.score,
    this.leadStatus,
    this.respondentName,
    this.respondentEmail,
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
    List<EnrichedAnswer>? answersData,
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
      _$AssessmentResultFromJson(
        json['result'] ?? json['assessmentResult'] ?? json,
      );
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

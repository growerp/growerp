import 'package:json_annotation/json_annotation.dart';

part 'assessment_question_option_model.g.dart';

/// Answer option for a multiple choice question
@JsonSerializable()
class AssessmentQuestionOption {
  /// System-wide unique identifier
  final String? assessmentQuestionOptionId;

  /// Tenant-unique identifier
  final String? pseudoId;

  /// Question ID this option belongs to
  final String? assessmentQuestionId;

  /// Assessment ID (for context)
  final String? assessmentId;

  /// Display order within question
  final int? optionSequence;

  /// Option text/label
  final String? optionText;

  /// Score value for this option
  final double? optionScore;

  /// Timestamp when created
  final DateTime? createdDate;

  const AssessmentQuestionOption({
    this.assessmentQuestionOptionId,
    this.pseudoId,
    this.assessmentQuestionId,
    this.assessmentId,
    this.optionSequence,
    this.optionText,
    this.optionScore,
    this.createdDate,
  });

  AssessmentQuestionOption copyWith({
    String? assessmentQuestionOptionId,
    String? pseudoId,
    String? assessmentQuestionId,
    String? assessmentId,
    int? optionSequence,
    String? optionText,
    double? optionScore,
    DateTime? createdDate,
  }) {
    return AssessmentQuestionOption(
      assessmentQuestionOptionId:
          assessmentQuestionOptionId ?? this.assessmentQuestionOptionId,
      pseudoId: pseudoId ?? this.pseudoId,
      assessmentQuestionId: assessmentQuestionId ?? this.assessmentQuestionId,
      assessmentId: assessmentId ?? this.assessmentId,
      optionSequence: optionSequence ?? this.optionSequence,
      optionText: optionText ?? this.optionText,
      optionScore: optionScore ?? this.optionScore,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  factory AssessmentQuestionOption.fromJson(Map<String, dynamic> json) =>
      _$AssessmentQuestionOptionFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentQuestionOptionToJson(this);

  @override
  String toString() =>
      'AssessmentQuestionOption(id: $assessmentQuestionOptionId, text: $optionText, score: $optionScore)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentQuestionOption &&
          runtimeType == other.runtimeType &&
          assessmentQuestionOptionId == other.assessmentQuestionOptionId;

  @override
  int get hashCode => assessmentQuestionOptionId.hashCode;
}

/// List wrapper for AssessmentQuestionOption objects
@JsonSerializable()
class AssessmentQuestionOptions {
  final List<AssessmentQuestionOption> options;

  const AssessmentQuestionOptions({required this.options});

  factory AssessmentQuestionOptions.fromJson(Map<String, dynamic> json) =>
      _$AssessmentQuestionOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentQuestionOptionsToJson(this);
}

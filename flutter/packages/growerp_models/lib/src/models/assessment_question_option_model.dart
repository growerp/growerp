import 'package:json_annotation/json_annotation.dart';

part 'assessment_question_option_model.g.dart';

/// Answer option for a multiple choice question
@JsonSerializable()
class AssessmentQuestionOption {
  /// System-wide unique identifier
  final String optionId;

  /// Tenant-unique identifier
  final String pseudoId;

  /// Question ID this option belongs to
  final String questionId;

  /// Assessment ID (for context)
  final String assessmentId;

  /// Display order within question
  final int optionSequence;

  /// Option text/label
  final String optionText;

  /// Score value for this option
  final double optionScore;

  /// Timestamp when created
  final DateTime createdDate;

  const AssessmentQuestionOption({
    required this.optionId,
    required this.pseudoId,
    required this.questionId,
    required this.assessmentId,
    required this.optionSequence,
    required this.optionText,
    required this.optionScore,
    required this.createdDate,
  });

  AssessmentQuestionOption copyWith({
    String? optionId,
    String? pseudoId,
    String? questionId,
    String? assessmentId,
    int? optionSequence,
    String? optionText,
    double? optionScore,
    DateTime? createdDate,
  }) {
    return AssessmentQuestionOption(
      optionId: optionId ?? this.optionId,
      pseudoId: pseudoId ?? this.pseudoId,
      questionId: questionId ?? this.questionId,
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
      'AssessmentQuestionOption(id: $optionId, text: $optionText, score: $optionScore)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentQuestionOption &&
          runtimeType == other.runtimeType &&
          optionId == other.optionId;

  @override
  int get hashCode => optionId.hashCode;
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

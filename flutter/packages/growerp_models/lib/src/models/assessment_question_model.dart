import 'package:json_annotation/json_annotation.dart';

part 'assessment_question_model.g.dart';

/// Assessment question model
///
/// Represents a single question within an assessment with options
@JsonSerializable()
class AssessmentQuestion {
  /// System-wide unique identifier
  final String questionId;

  /// Tenant-unique identifier
  final String pseudoId;

  /// Assessment ID this question belongs to
  final String assessmentId;

  /// Display order within assessment
  final int questionSequence;

  /// Question type: text, email, radio, dropdown, yes_no
  final String questionType;

  /// Question text/prompt
  final String questionText;

  /// Optional question description
  final String? questionDescription;

  /// Whether this question is required
  final bool isRequired;

  /// Timestamp when created
  final DateTime createdDate;

  /// Username who created this question
  final String? createdByUserLogin;

  const AssessmentQuestion({
    required this.questionId,
    required this.pseudoId,
    required this.assessmentId,
    required this.questionSequence,
    required this.questionType,
    required this.questionText,
    this.questionDescription,
    required this.isRequired,
    required this.createdDate,
    this.createdByUserLogin,
  });

  /// Creates a copy with optionally replaced fields
  AssessmentQuestion copyWith({
    String? questionId,
    String? pseudoId,
    String? assessmentId,
    int? questionSequence,
    String? questionType,
    String? questionText,
    String? questionDescription,
    bool? isRequired,
    DateTime? createdDate,
    String? createdByUserLogin,
  }) {
    return AssessmentQuestion(
      questionId: questionId ?? this.questionId,
      pseudoId: pseudoId ?? this.pseudoId,
      assessmentId: assessmentId ?? this.assessmentId,
      questionSequence: questionSequence ?? this.questionSequence,
      questionType: questionType ?? this.questionType,
      questionText: questionText ?? this.questionText,
      questionDescription: questionDescription ?? this.questionDescription,
      isRequired: isRequired ?? this.isRequired,
      createdDate: createdDate ?? this.createdDate,
      createdByUserLogin: createdByUserLogin ?? this.createdByUserLogin,
    );
  }

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) =>
      _$AssessmentQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentQuestionToJson(this);

  @override
  String toString() =>
      'AssessmentQuestion(id: $questionId, type: $questionType, seq: $questionSequence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentQuestion &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId;

  @override
  int get hashCode => questionId.hashCode;
}

/// List wrapper for AssessmentQuestion objects
@JsonSerializable()
class AssessmentQuestions {
  final List<AssessmentQuestion> questions;

  const AssessmentQuestions({required this.questions});

  factory AssessmentQuestions.fromJson(Map<String, dynamic> json) =>
      _$AssessmentQuestionsFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentQuestionsToJson(this);
}

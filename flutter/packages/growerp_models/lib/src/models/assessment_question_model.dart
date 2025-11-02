import 'package:json_annotation/json_annotation.dart';
import 'assessment_question_option_model.dart';

part 'assessment_question_model.g.dart';

/// Converter to handle Moqui's Y/N string booleans
class StringBoolConverter implements JsonConverter<bool, dynamic> {
  const StringBoolConverter();

  @override
  bool fromJson(dynamic json) {
    if (json is bool) return json;
    if (json is String) return json.toUpperCase() == 'Y';
    return false;
  }

  @override
  dynamic toJson(bool object) => object ? 'Y' : 'N';
}

/// Assessment question model
///
/// Represents a single question within an assessment with options
@JsonSerializable()
class AssessmentQuestion {
  /// System-wide unique identifier
  final String? questionId;

  /// Tenant-unique identifier
  final String? pseudoId;

  /// Assessment ID this question belongs to
  final String? assessmentId;

  /// Display order within assessment
  final int? questionSequence;

  /// Question type: text, email, radio, dropdown, yes_no
  final String? questionType;

  /// Question text/prompt
  final String? questionText;

  /// Optional question description
  final String? questionDescription;

  /// Whether this question is required (Moqui sends as 'Y' or 'N')
  @StringBoolConverter()
  final bool? isRequired;

  /// Timestamp when created
  final DateTime? createdDate;

  /// Username who created this question
  final String? createdByUserLogin;

  /// Answer options for this question (when fetched with nested options)
  final List<AssessmentQuestionOption>? options;

  const AssessmentQuestion({
    this.questionId,
    this.pseudoId,
    this.assessmentId,
    this.questionSequence,
    this.questionType,
    this.questionText,
    this.questionDescription,
    this.isRequired,
    this.createdDate,
    this.createdByUserLogin,
    this.options,
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
    List<AssessmentQuestionOption>? options,
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
      options: options ?? this.options,
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

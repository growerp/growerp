import 'package:json_annotation/json_annotation.dart';
import 'assessment_question_model.dart';

part 'assessment_questions_response_model.g.dart';

/// Response model for assessment questions API
@JsonSerializable()
class AssessmentQuestionsResponse {
  /// List of questions
  final List<AssessmentQuestion> questions;

  /// Total number of questions (for pagination)
  final int? questionCount;

  const AssessmentQuestionsResponse({
    required this.questions,
    this.questionCount,
  });

  factory AssessmentQuestionsResponse.fromJson(Map<String, dynamic> json) =>
      _$AssessmentQuestionsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentQuestionsResponseToJson(this);

  @override
  String toString() =>
      'AssessmentQuestionsResponse(questions: ${questions.length}, total: $questionCount)';
}

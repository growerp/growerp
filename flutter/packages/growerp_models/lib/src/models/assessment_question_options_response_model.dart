import 'package:json_annotation/json_annotation.dart';
import 'assessment_question_option_model.dart';

part 'assessment_question_options_response_model.g.dart';

/// Response model for assessment question options API
@JsonSerializable()
class AssessmentQuestionOptionsResponse {
  /// List of options
  final List<AssessmentQuestionOption> options;

  /// Total number of options (for pagination)
  final int? optionCount;

  const AssessmentQuestionOptionsResponse({
    required this.options,
    this.optionCount,
  });

  factory AssessmentQuestionOptionsResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$AssessmentQuestionOptionsResponseFromJson(json);
  Map<String, dynamic> toJson() =>
      _$AssessmentQuestionOptionsResponseToJson(this);

  @override
  String toString() =>
      'AssessmentQuestionOptionsResponse(options: ${options.length}, total: $optionCount)';
}

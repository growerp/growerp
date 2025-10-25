import 'package:json_annotation/json_annotation.dart';

part 'assessment_score_response_model.g.dart';

/// Response model for assessment score calculation
@JsonSerializable()
class AssessmentScoreResponse {
  /// Calculated score
  final double score;

  /// Lead status/category based on score
  final String? leadStatus;

  /// Additional calculation details
  final Map<String, dynamic>? details;

  const AssessmentScoreResponse({
    required this.score,
    this.leadStatus,
    this.details,
  });

  factory AssessmentScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$AssessmentScoreResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AssessmentScoreResponseToJson(this);

  @override
  String toString() =>
      'AssessmentScoreResponse(score: $score, status: $leadStatus)';
}

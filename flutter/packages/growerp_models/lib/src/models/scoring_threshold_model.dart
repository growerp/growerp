import 'package:json_annotation/json_annotation.dart';
import 'assessment_model.dart' show NullableTimestampConverter;

part 'scoring_threshold_model.g.dart';

/// Score threshold that determines assessment outcome
@JsonSerializable()
class ScoringThreshold {
  /// System-wide unique identifier
  final String? scoringThresholdId;

  /// Tenant-unique identifier
  final String? pseudoId;

  /// Assessment ID this threshold belongs to
  final String? assessmentId;

  /// Minimum score for this threshold (inclusive)
  final double? minScore;

  /// Maximum score for this threshold (inclusive)
  final double? maxScore;

  /// Lead status/category assigned at this score range
  final String? leadStatus;

  /// Description of this score range outcome
  final String? description;

  /// Timestamp when created
  @NullableTimestampConverter()
  final DateTime? createdDate;

  const ScoringThreshold({
    this.scoringThresholdId,
    this.pseudoId,
    this.assessmentId,
    this.minScore,
    this.maxScore,
    this.leadStatus,
    this.description,
    this.createdDate,
  });

  ScoringThreshold copyWith({
    String? scoringThresholdId,
    String? pseudoId,
    String? assessmentId,
    double? minScore,
    double? maxScore,
    String? leadStatus,
    String? description,
    DateTime? createdDate,
  }) {
    return ScoringThreshold(
      scoringThresholdId: scoringThresholdId ?? this.scoringThresholdId,
      pseudoId: pseudoId ?? this.pseudoId,
      assessmentId: assessmentId ?? this.assessmentId,
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      leadStatus: leadStatus ?? this.leadStatus,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  factory ScoringThreshold.fromJson(Map<String, dynamic> json) =>
      _$ScoringThresholdFromJson(json);
  Map<String, dynamic> toJson() => _$ScoringThresholdToJson(this);

  @override
  String toString() =>
      'ScoringThreshold(id: $scoringThresholdId, range: $minScore-$maxScore, status: $leadStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoringThreshold &&
          runtimeType == other.runtimeType &&
          scoringThresholdId == other.scoringThresholdId;

  @override
  int get hashCode => scoringThresholdId.hashCode;
}

/// List wrapper for ScoringThreshold objects
@JsonSerializable()
class ScoringThresholds {
  final List<ScoringThreshold> thresholds;

  const ScoringThresholds({required this.thresholds});

  factory ScoringThresholds.fromJson(Map<String, dynamic> json) =>
      _$ScoringThresholdsFromJson(json);
  Map<String, dynamic> toJson() => _$ScoringThresholdsToJson(this);
}

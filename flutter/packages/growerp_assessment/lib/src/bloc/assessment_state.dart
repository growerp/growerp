/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

part of 'assessment_bloc.dart';

enum AssessmentStatus { initial, loading, success, failure }

class AssessmentState extends Equatable {
  const AssessmentState({
    this.status = AssessmentStatus.initial,
    this.assessments = const <Assessment>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.selectedAssessment,
    this.questions = const <AssessmentQuestion>[],
    this.options = const <String, List<AssessmentQuestionOption>>{},
    this.thresholds = const <ScoringThreshold>[],
    this.results = const <AssessmentResult>[],
    this.scoreResult,
  });

  final AssessmentStatus status;
  final String? message;
  final List<Assessment> assessments;
  final bool hasReachedMax;
  final String searchString;
  final Assessment? selectedAssessment;
  final List<AssessmentQuestion> questions;
  final Map<String, List<AssessmentQuestionOption>> options;
  final List<ScoringThreshold> thresholds;
  final List<AssessmentResult> results;
  final AssessmentScoreResponse? scoreResult;

  AssessmentState copyWith({
    AssessmentStatus? status,
    String? message,
    List<Assessment>? assessments,
    bool? hasReachedMax,
    String? searchString,
    Assessment? selectedAssessment,
    List<AssessmentQuestion>? questions,
    Map<String, List<AssessmentQuestionOption>>? options,
    List<ScoringThreshold>? thresholds,
    List<AssessmentResult>? results,
    AssessmentScoreResponse? scoreResult,
  }) {
    return AssessmentState(
      status: status ?? this.status,
      assessments: assessments ?? this.assessments,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      selectedAssessment: selectedAssessment ?? this.selectedAssessment,
      questions: questions ?? this.questions,
      options: options ?? this.options,
      thresholds: thresholds ?? this.thresholds,
      results: results ?? this.results,
      scoreResult: scoreResult ?? this.scoreResult,
    );
  }

  @override
  List<Object?> get props => [
        status,
        hasReachedMax,
        message,
        assessments,
        searchString,
        selectedAssessment,
        questions,
        options,
        thresholds,
        results,
        scoreResult,
      ];

  @override
  String toString() => '$status { #assessments: ${assessments.length}, '
      'hasReachedMax: $hasReachedMax, message: $message, '
      'selectedAssessment: ${selectedAssessment?.assessmentName}}';
}

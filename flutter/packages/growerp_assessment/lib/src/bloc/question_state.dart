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

import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

enum QuestionStatus { initial, loading, success, failure }

class QuestionState extends Equatable {
  const QuestionState({
    this.status = QuestionStatus.initial,
    this.questions = const [],
    this.selectedQuestion,
    this.assessmentId,
    this.message,
  });

  final QuestionStatus status;
  final List<AssessmentQuestion> questions;
  final AssessmentQuestion? selectedQuestion;
  final String? assessmentId;
  final String? message;

  QuestionState copyWith({
    QuestionStatus? status,
    List<AssessmentQuestion>? questions,
    AssessmentQuestion? selectedQuestion,
    String? assessmentId,
    String? message,
    bool clearSelectedQuestion = false,
  }) {
    return QuestionState(
      status: status ?? this.status,
      questions: questions ?? this.questions,
      selectedQuestion:
          clearSelectedQuestion ? null : selectedQuestion ?? this.selectedQuestion,
      assessmentId: assessmentId ?? this.assessmentId,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        questions,
        selectedQuestion,
        assessmentId,
        message,
      ];

  @override
  String toString() =>
      'QuestionState { status: $status, questions: ${questions.length}, assessmentId: $assessmentId }';
}

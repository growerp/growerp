/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
      selectedQuestion: clearSelectedQuestion
          ? null
          : selectedQuestion ?? this.selectedQuestion,
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

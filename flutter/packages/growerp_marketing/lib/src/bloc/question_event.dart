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

abstract class QuestionEvent extends Equatable {
  const QuestionEvent();
  @override
  List<Object?> get props => [];
}

class QuestionLoad extends QuestionEvent {
  final String assessmentId;
  const QuestionLoad(this.assessmentId);
  @override
  List<Object?> get props => [assessmentId];
}

class QuestionCreate extends QuestionEvent {
  final String assessmentId;
  final String questionText;
  final String? questionDescription;
  final String? questionType;
  final int? questionSequence;
  final bool? isRequired;
  final List<AssessmentQuestionOption>? options;

  const QuestionCreate({
    required this.assessmentId,
    required this.questionText,
    this.questionDescription,
    this.questionType,
    this.questionSequence,
    this.isRequired,
    this.options,
  });

  @override
  List<Object?> get props => [
        assessmentId,
        questionText,
        questionDescription,
        questionType,
        questionSequence,
        isRequired,
        options,
      ];
}

class QuestionUpdate extends QuestionEvent {
  final String assessmentId;
  final String questionId;
  final String? questionText;
  final String? questionDescription;
  final String? questionType;
  final int? questionSequence;
  final bool? isRequired;
  final List<AssessmentQuestionOption>? options;

  const QuestionUpdate({
    required this.assessmentId,
    required this.questionId,
    this.questionText,
    this.questionDescription,
    this.questionType,
    this.questionSequence,
    this.isRequired,
    this.options,
  });

  @override
  List<Object?> get props => [
        assessmentId,
        questionId,
        questionText,
        questionDescription,
        questionType,
        questionSequence,
        isRequired,
        options,
      ];
}

class QuestionDelete extends QuestionEvent {
  final String questionId;
  const QuestionDelete(this.questionId);
  @override
  List<Object?> get props => [questionId];
}

class QuestionClear extends QuestionEvent {
  const QuestionClear();
}

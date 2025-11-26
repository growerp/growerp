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

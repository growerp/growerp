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

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// A learner taking the quiz of one module: load, answer, submit, retry.

abstract class CourseQuizEvent extends Equatable {
  const CourseQuizEvent();
  @override
  List<Object?> get props => [];
}

class CourseQuizLoad extends CourseQuizEvent {
  const CourseQuizLoad();
}

class CourseQuizAnswer extends CourseQuizEvent {
  final int questionIndex;
  final int optionIndex;
  const CourseQuizAnswer(this.questionIndex, this.optionIndex);
  @override
  List<Object?> get props => [questionIndex, optionIndex];
}

class CourseQuizSubmit extends CourseQuizEvent {
  const CourseQuizSubmit();
}

/// Take the quiz again: clears the answers and the result
class CourseQuizRetry extends CourseQuizEvent {
  const CourseQuizRetry();
}

enum CourseQuizStatus { loading, answering, submitting, submitted, failure }

class CourseQuizState extends Equatable {
  final CourseQuizStatus status;
  final List<CourseQuizQuestion> questions;
  final List<int?> answers;
  final CourseQuizResult? result;
  final String? message;

  const CourseQuizState({
    this.status = CourseQuizStatus.loading,
    this.questions = const [],
    this.answers = const [],
    this.result,
    this.message,
  });

  bool get allAnswered =>
      answers.length == questions.length && !answers.contains(null);

  CourseQuizState copyWith({
    CourseQuizStatus? status,
    List<CourseQuizQuestion>? questions,
    List<int?>? answers,
    CourseQuizResult? result,
    String? message,
  }) => CourseQuizState(
    status: status ?? this.status,
    questions: questions ?? this.questions,
    answers: answers ?? this.answers,
    result: result,
    message: message,
  );

  @override
  List<Object?> get props => [status, questions, answers, result, message];
}

class CourseQuizBloc extends Bloc<CourseQuizEvent, CourseQuizState> {
  final RestClient restClient;
  final String courseId;
  final String moduleId;

  CourseQuizBloc({
    required this.restClient,
    required this.courseId,
    required this.moduleId,
  }) : super(const CourseQuizState()) {
    on<CourseQuizLoad>(_onLoad);
    on<CourseQuizAnswer>(_onAnswer);
    on<CourseQuizSubmit>(_onSubmit);
    on<CourseQuizRetry>(_onRetry);
  }

  Future<void> _onLoad(
    CourseQuizLoad event,
    Emitter<CourseQuizState> emit,
  ) async {
    try {
      final quiz = await restClient.getCourseQuiz(
        courseId: courseId,
        moduleId: moduleId,
      );
      emit(
        CourseQuizState(
          status: CourseQuizStatus.answering,
          questions: quiz.questions,
          answers: List.filled(quiz.questions.length, null),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseQuizStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  void _onAnswer(CourseQuizAnswer event, Emitter<CourseQuizState> emit) {
    if (state.status != CourseQuizStatus.answering) return;
    // a new list: state lists may be const
    final answers = List<int?>.of(state.answers);
    answers[event.questionIndex] = event.optionIndex;
    emit(state.copyWith(answers: answers));
  }

  Future<void> _onSubmit(
    CourseQuizSubmit event,
    Emitter<CourseQuizState> emit,
  ) async {
    emit(state.copyWith(status: CourseQuizStatus.submitting));
    try {
      final result = await restClient.submitCourseQuiz(
        courseId: courseId,
        moduleId: moduleId,
        answers: state.answers,
      );
      emit(state.copyWith(status: CourseQuizStatus.submitted, result: result));
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseQuizStatus.answering,
          message: await getDioError(e),
        ),
      );
    }
  }

  void _onRetry(CourseQuizRetry event, Emitter<CourseQuizState> emit) {
    emit(
      state.copyWith(
        status: CourseQuizStatus.answering,
        answers: List.filled(state.questions.length, null),
      ),
    );
  }
}

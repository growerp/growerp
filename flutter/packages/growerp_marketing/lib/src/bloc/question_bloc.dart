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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'question_event.dart';
import 'question_state.dart';

class QuestionBloc extends Bloc<QuestionEvent, QuestionState> {
  final RestClient restClient;

  QuestionBloc({
    required this.restClient,
  }) : super(const QuestionState()) {
    on<QuestionLoad>(_onQuestionLoad);
    on<QuestionCreate>(_onQuestionCreate);
    on<QuestionUpdate>(_onQuestionUpdate);
    on<QuestionDelete>(_onQuestionDelete);
    on<QuestionClear>(_onQuestionClear);
  }

  Future<void> _onQuestionLoad(
    QuestionLoad event,
    Emitter<QuestionState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: QuestionStatus.loading,
        assessmentId: event.assessmentId,
      ));

      final response = await restClient.getAssessmentQuestions(
        assessmentId: event.assessmentId,
      );

      emit(state.copyWith(
        status: QuestionStatus.success,
        questions: response.questions,
        assessmentId: event.assessmentId,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: QuestionStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onQuestionCreate(
    QuestionCreate event,
    Emitter<QuestionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: QuestionStatus.loading));

      // Convert options to Map format for API
      final optionsData = event.options
          ?.map((opt) => {
                'optionText': opt.optionText,
                'optionScore': opt.optionScore,
                'optionSequence': opt.optionSequence,
              })
          .toList();

      // Create the question with options in a single call
      final newQuestion = await restClient.createAssessmentQuestion(
        assessmentId: event.assessmentId,
        questionText: event.questionText,
        questionDescription: event.questionDescription,
        questionType: event.questionType ?? 'MULTIPLE_CHOICE',
        questionSequence: event.questionSequence,
        isRequired: event.isRequired == true ? 'Y' : 'N',
        options: optionsData,
      );

      // Add new question to the list
      final updatedQuestions = [...state.questions, newQuestion];

      emit(state.copyWith(
        status: QuestionStatus.success,
        questions: updatedQuestions,
        selectedQuestion: newQuestion,
        message: 'Question created successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: QuestionStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onQuestionUpdate(
    QuestionUpdate event,
    Emitter<QuestionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: QuestionStatus.loading));

      // Convert options to Map format for API
      final optionsData = event.options
          ?.map((opt) => {
                'optionText': opt.optionText,
                'optionScore': opt.optionScore,
                'optionSequence': opt.optionSequence,
              })
          .toList();

      // Update the question with options in a single call
      final updatedQuestion = await restClient.updateAssessmentQuestion(
        assessmentId: event.assessmentId,
        questionId: event.questionId,
        questionText: event.questionText,
        questionDescription: event.questionDescription,
        questionType: event.questionType,
        questionSequence: event.questionSequence,
        isRequired: event.isRequired == true ? 'Y' : 'N',
        options: optionsData,
      );

      // Replace the updated question in the list
      final updatedQuestions = state.questions.map((q) {
        return q.assessmentQuestionId == event.questionId ? updatedQuestion : q;
      }).toList();

      emit(state.copyWith(
        status: QuestionStatus.success,
        questions: updatedQuestions,
        selectedQuestion: updatedQuestion,
        message: 'Question updated successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: QuestionStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onQuestionDelete(
    QuestionDelete event,
    Emitter<QuestionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: QuestionStatus.loading));

      await restClient.deleteAssessmentQuestion(
        assessmentId: state.assessmentId!,
        questionId: event.questionId,
      );

      final updatedQuestions = state.questions
          .where(
              (question) => question.assessmentQuestionId != event.questionId)
          .toList();

      emit(state.copyWith(
        status: QuestionStatus.success,
        questions: updatedQuestions,
        message: 'Question deleted successfully',
        clearSelectedQuestion: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: QuestionStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onQuestionClear(
    QuestionClear event,
    Emitter<QuestionState> emit,
  ) async {
    emit(state.copyWith(clearSelectedQuestion: true));
  }
}

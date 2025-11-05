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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
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

      // Create the question first
      final newQuestion = await restClient.createAssessmentQuestion(
        assessmentId: event.assessmentId,
        questionText: event.questionText,
        questionType: event.questionType,
        questionSequence: event.questionSequence,
        isRequired: event.isRequired == true ? 'Y' : 'N',
      );

      // If options provided, create them
      List<AssessmentQuestionOption> createdOptions = [];
      if (event.options != null && event.options!.isNotEmpty) {
        for (var option in event.options!) {
          final createdOption = await restClient.createAssessmentQuestionOption(
            assessmentId: event.assessmentId,
            questionId: newQuestion.assessmentQuestionId!,
            optionText: option.optionText!,
            optionScore: option.optionScore ?? 0.0,
            optionSequence: option.optionSequence,
          );
          createdOptions.add(createdOption);
        }
      }

      // Update question with options
      final questionWithOptions = newQuestion.copyWith(options: createdOptions);

      final updatedQuestions = List<AssessmentQuestion>.from(state.questions)
        ..add(questionWithOptions)
        ..sort((a, b) =>
            (a.questionSequence ?? 0).compareTo(b.questionSequence ?? 0));

      emit(state.copyWith(
        status: QuestionStatus.success,
        questions: updatedQuestions,
        selectedQuestion: questionWithOptions,
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

      // Update the question
      final updatedQuestion = await restClient.updateAssessmentQuestion(
        assessmentId: event.assessmentId,
        questionId: event.questionId,
        questionText: event.questionText,
        questionType: event.questionType,
        questionSequence: event.questionSequence,
        isRequired: event.isRequired == true ? 'Y' : 'N',
      );

      // Handle options update if provided
      List<AssessmentQuestionOption> finalOptions = [];
      if (event.options != null) {
        // Get existing options
        final existingOptionsResponse =
            await restClient.getAssessmentQuestionOptions(
          assessmentId: event.assessmentId,
          assessmentQuestionId: event.questionId,
        );
        final existingOptions = existingOptionsResponse.options;

        // Delete options that are not in the new list
        for (var existing in existingOptions) {
          final stillExists = event.options!.any((opt) =>
              opt.assessmentQuestionOptionId ==
              existing.assessmentQuestionOptionId);
          if (!stillExists) {
            await restClient.deleteAssessmentQuestionOption(
              assessmentId: event.assessmentId,
              questionId: event.questionId,
              optionId: existing.assessmentQuestionOptionId!,
            );
          }
        }

        // Create or update options
        for (var option in event.options!) {
          if (option.assessmentQuestionOptionId == null ||
              option.assessmentQuestionOptionId!.isEmpty) {
            // Create new option
            final created = await restClient.createAssessmentQuestionOption(
              assessmentId: event.assessmentId,
              questionId: event.questionId,
              optionText: option.optionText!,
              optionScore: option.optionScore ?? 0.0,
              optionSequence: option.optionSequence,
            );
            finalOptions.add(created);
          } else {
            // Update existing option
            final updated = await restClient.updateAssessmentQuestionOption(
              assessmentId: event.assessmentId,
              questionId: event.questionId,
              optionId: option.assessmentQuestionOptionId!,
              optionText: option.optionText,
              optionScore: option.optionScore,
              optionSequence: option.optionSequence,
            );
            finalOptions.add(updated);
          }
        }
      }

      final questionWithOptions = updatedQuestion.copyWith(options: finalOptions);

      final updatedQuestions = state.questions
          .map((question) =>
              question.assessmentQuestionId == updatedQuestion.assessmentQuestionId
                  ? questionWithOptions
                  : question)
          .toList()
        ..sort((a, b) =>
            (a.questionSequence ?? 0).compareTo(b.questionSequence ?? 0));

      emit(state.copyWith(
        status: QuestionStatus.success,
        questions: updatedQuestions,
        selectedQuestion: questionWithOptions,
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
          .where((question) => question.assessmentQuestionId != event.questionId)
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

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

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'assessment_event.dart';
part 'assessment_state.dart';

EventTransformer<E> assessmentDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class AssessmentBloc extends Bloc<AssessmentEvent, AssessmentState> {
  final RestClient restClient;
  int start = 0;

  AssessmentBloc(this.restClient) : super(const AssessmentState()) {
    on<AssessmentFetch>(
      _onAssessmentFetch,
      transformer: assessmentDroppable(const Duration(milliseconds: 100)),
    );
    on<AssessmentFetchAll>(_onAssessmentFetchAll);
    on<AssessmentCreate>(_onAssessmentCreate);
    on<AssessmentUpdate>(_onAssessmentUpdate);
    on<AssessmentDelete>(_onAssessmentDelete);
    on<AssessmentSubmit>(_onAssessmentSubmit);
    on<AssessmentCalculateScore>(_onAssessmentCalculateScore);
    on<AssessmentFetchResults>(_onAssessmentFetchResults);
    on<AssessmentFetchQuestions>(_onAssessmentFetchQuestions);
    on<AssessmentFetchQuestionOptions>(_onAssessmentFetchQuestionOptions);
    on<AssessmentFetchThresholds>(_onAssessmentFetchThresholds);
  }

  Future<void> _onAssessmentFetch(
    AssessmentFetch event,
    Emitter<AssessmentState> emit,
  ) async {
    List<Assessment> current = [];
    if (state.status == AssessmentStatus.initial ||
        event.refresh ||
        event.searchString.isNotEmpty) {
      start = 0;
      current = [];
    } else {
      start = state.assessments.length;
      current = List.of(state.assessments);
    }

    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      final response = await restClient.getAssessment(
        start: start,
        limit: event.limit,
        statusId: event.statusId,
        searchString: event.searchString.isEmpty ? null : event.searchString,
      );

      emit(state.copyWith(
        status: AssessmentStatus.success,
        assessments: response.assessments,
        hasReachedMax: response.assessments.length < event.limit,
        searchString: event.searchString,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }

  Future<void> _onAssessmentFetchAll(
    AssessmentFetchAll event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      final assessment = await restClient.getAssessmentComplete(
        assessmentId: event.assessmentId,
        pseudoId: event.pseudoId,
        ownerPartyId: event.ownerPartyId,
      );

      emit(state.copyWith(
        status: AssessmentStatus.success,
        selectedAssessment: assessment,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onAssessmentCreate(
    AssessmentCreate event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      final assessment = await restClient.createAssessment(
        assessmentName: event.assessment.assessmentName,
        description: event.assessment.description,
        status: event.assessment.status,
      );

      emit(state.copyWith(
        status: AssessmentStatus.success,
        selectedAssessment: assessment,
        assessments: [assessment, ...state.assessments],
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }

  Future<void> _onAssessmentUpdate(
    AssessmentUpdate event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      final assessment = await restClient
          .updateAssessment(
            assessmentId: event.assessment.assessmentId,
            pseudoId: event.assessment.pseudoId,
            assessmentName: event.assessment.assessmentName,
            description: event.assessment.description,
            status: event.assessment.status,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Assessment update timed out after 30 seconds'),
          );

      final updatedAssessments = state.assessments
          .map(
              (a) => a.assessmentId == assessment.assessmentId ? assessment : a)
          .toList();

      emit(state.copyWith(
        status: AssessmentStatus.success,
        selectedAssessment: assessment,
        assessments: updatedAssessments,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onAssessmentDelete(
    AssessmentDelete event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      await restClient.deleteAssessment(
        assessmentId: event.assessment.assessmentId,
      );

      final updatedAssessments = state.assessments
          .where((a) => a.assessmentId != event.assessment.assessmentId)
          .toList();

      emit(state.copyWith(
        status: AssessmentStatus.success,
        assessments: updatedAssessments,
        selectedAssessment: state.selectedAssessment?.assessmentId ==
                event.assessment.assessmentId
            ? null
            : state.selectedAssessment,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }

  Future<void> _onAssessmentSubmit(
    AssessmentSubmit event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      // Convert answers Map to JSON string
      final answersJson = jsonEncode(event.answers);

      final result = await restClient.submitAssessment(
        assessmentId: event.assessmentId,
        answers: answersJson,
        respondentName: event.respondentName,
        respondentEmail: event.respondentEmail,
        respondentPhone: event.respondentPhone,
        respondentCompany: event.respondentCompany,
      );

      emit(state.copyWith(
        status: AssessmentStatus.success,
        results: [result, ...state.results],
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }

  Future<void> _onAssessmentCalculateScore(
    AssessmentCalculateScore event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      // Convert answers Map to JSON string
      final answersJson = jsonEncode(event.answers);

      final scoreResult = await restClient.calculateAssessmentScore(
        assessmentId: event.assessmentId,
        answers: answersJson,
      );

      emit(state.copyWith(
        status: AssessmentStatus.success,
        scoreResult: scoreResult,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }

  Future<void> _onAssessmentFetchResults(
    AssessmentFetchResults event,
    Emitter<AssessmentState> emit,
  ) async {
    List<AssessmentResult> current = [];
    if (event.refresh) {
      current = [];
    } else {
      current = List.of(state.results);
    }

    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      final AssessmentResults response;
      if (event.assessmentId.isEmpty) {
        // Get all results across all assessments
        response = await restClient.getAllAssessmentResults(
          start: event.start,
          limit: event.limit,
        );
      } else {
        // Get results for specific assessment
        response = await restClient.getAssessmentResults(
          assessmentId: event.assessmentId,
          start: event.start,
          limit: event.limit,
        );
      }

      emit(state.copyWith(
        status: AssessmentStatus.success,
        results: current..addAll(response.results),
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }

  Future<void> _onAssessmentFetchQuestions(
    AssessmentFetchQuestions event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      final questionsResponse = await restClient.getAssessmentQuestions(
        assessmentId: event.assessmentId,
      );

      emit(state.copyWith(
        status: AssessmentStatus.success,
        questions: questionsResponse.questions,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }

  Future<void> _onAssessmentFetchQuestionOptions(
    AssessmentFetchQuestionOptions event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      final optionsResponse = await restClient.getAssessmentQuestionOptions(
        assessmentId: event.assessmentId,
        assessmentQuestionId: event.assessmentQuestionId,
      );

      // Update the options map with the new options for this question
      final updatedOptions =
          Map<String, List<AssessmentQuestionOption>>.from(state.options);
      updatedOptions[event.assessmentQuestionId] = optionsResponse.options;

      emit(state.copyWith(
        status: AssessmentStatus.success,
        options: updatedOptions,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }

  Future<void> _onAssessmentFetchThresholds(
    AssessmentFetchThresholds event,
    Emitter<AssessmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssessmentStatus.loading));

      final thresholdsResponse = await restClient.getAssessmentThresholds(
        assessmentId: event.assessmentId,
      );

      emit(state.copyWith(
        status: AssessmentStatus.success,
        thresholds: thresholdsResponse.thresholds,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: AssessmentStatus.failure,
        message: await getDioError(e),
      ));
    }
  }
}

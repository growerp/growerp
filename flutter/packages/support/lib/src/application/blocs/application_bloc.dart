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

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';

part 'application_event.dart';
part 'application_state.dart';

EventTransformer<E> applicationDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ApplicationBloc extends Bloc<ApplicationEvent, ApplicationState> {
  ApplicationBloc(this.restClient) : super(const ApplicationState()) {
    on<ApplicationFetch>(
      _onApplicationFetch,
      transformer: applicationDroppable(const Duration(milliseconds: 100)),
    );
    on<ApplicationUpdate>(_onApplicationUpdate);
    on<ApplicationDelete>(_onApplicationDelete);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onApplicationFetch(
    ApplicationFetch event,
    Emitter<ApplicationState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString == '') return;

    List<Application> current = [];
    if (state.status == ApplicationStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
      current = [];
    } else {
      start = state.applications.length;
      current = List.of(state.applications);
    }
    try {
      Applications appResult = await restClient.getApplication();
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          applications: current..addAll(appResult.applications),
          hasReachedMax: appResult.applications.length < event.limit,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ApplicationStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onApplicationUpdate(
    ApplicationUpdate event,
    Emitter<ApplicationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ApplicationStatus.loading));

      List<Application> applications = List.from(state.applications);
      if (event.application.applicationId.isNotEmpty) {
        // This is an update, but the API doesn't have an update method
        // We'll delete and re-add the application in the backend
        Application appResult = await restClient.createApplication(
          event.application,
        );

        int index = applications.indexWhere(
          (element) => element.applicationId == event.application.applicationId,
        );
        if (index != -1) {
          applications[index] = appResult;
        } else {
          applications.insert(0, appResult);
        }

        emit(
          state.copyWith(
            status: ApplicationStatus.success,
            applications: applications,
            message: 'Application ${event.application.applicationId} updated!',
          ),
        );
      } else {
        // add
        Application appResult = await restClient.createApplication(
          event.application,
        );

        applications.insert(0, appResult);
        emit(
          state.copyWith(
            status: ApplicationStatus.success,
            applications: applications,
            message: 'Application ${event.application.applicationId} added!',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ApplicationStatus.failure,
          applications: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onApplicationDelete(
    ApplicationDelete event,
    Emitter<ApplicationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ApplicationStatus.loading));
      List<Application> applications = List.from(state.applications);

      await restClient.deleteApplication(event.application);
      int index = applications.indexWhere(
        (element) => element.applicationId == event.application.applicationId,
      );
      // Keep the entry in the list but clear its content
      applications[index] = Application(
        applicationId: event.application.applicationId,
      );
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          applications: applications,
          message: 'Application ${event.application.applicationId} deleted!',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: ApplicationStatus.failure,
          applications: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}

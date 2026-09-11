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

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'onboarding_task_event.dart';
part 'onboarding_task_state.dart';

const _throttleDuration = Duration(milliseconds: 100);
const _searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Search keystrokes are debounced and the running search is cancelled by the
/// next one: a dropping transformer would lose the last keystroke.
EventTransformer<OnboardingTaskSearchChanged> _searchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.isNotEmpty)
        .debounce(_searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class OnboardingTaskBloc
    extends Bloc<OnboardingTaskEvent, OnboardingTaskState> {
  final RestClient restClient;

  OnboardingTaskBloc(this.restClient) : super(const OnboardingTaskState()) {
    on<OnboardingTasksFetch>(
      _onOnboardingTasksFetch,
      transformer: _throttleDroppable(_throttleDuration),
    );
    on<OnboardingTaskSearchChanged>(
      _onOnboardingTaskSearchChanged,
      transformer: _searchDebounce(),
    );
    on<OnboardingTaskUpdate>(_onOnboardingTaskUpdate);
    on<OnboardingTaskDelete>(_onOnboardingTaskDelete);
  }

  Future<void> _onOnboardingTasksFetch(
    OnboardingTasksFetch event,
    Emitter<OnboardingTaskState> emit,
  ) async {
    if (state.hasReachedMax &&
        !event.refresh &&
        event.searchString == state.searchString) {
      return;
    }
    try {
      emit(state.copyWith(status: OnboardingTaskStatus.loading));
      if (event.refresh || event.searchString != state.searchString) {
        final result = await restClient.getOnboardingTasks(
          search: event.searchString.isEmpty ? null : event.searchString,
          start: 0,
          limit: event.limit,
        );
        return emit(
          state.copyWith(
            status: OnboardingTaskStatus.success,
            onboardingTasks: result.onboardingTasks,
            hasReachedMax: result.onboardingTasks.length < event.limit,
            searchString: event.searchString,
          ),
        );
      }
      final result = await restClient.getOnboardingTasks(
        search: event.searchString.isEmpty ? null : event.searchString,
        start: state.onboardingTasks.length,
        limit: event.limit,
      );
      emit(
        result.onboardingTasks.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: OnboardingTaskStatus.success,
                onboardingTasks: [
                  ...state.onboardingTasks,
                  ...result.onboardingTasks,
                ],
                hasReachedMax: result.onboardingTasks.length < event.limit,
              ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OnboardingTaskStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onOnboardingTaskSearchChanged(
    OnboardingTaskSearchChanged event,
    Emitter<OnboardingTaskState> emit,
  ) async {
    return _onOnboardingTasksFetch(
      OnboardingTasksFetch(refresh: true, searchString: event.searchString),
      emit,
    );
  }

  Future<void> _onOnboardingTaskUpdate(
    OnboardingTaskUpdate event,
    Emitter<OnboardingTaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OnboardingTaskStatus.loading));
      OnboardingTask updated;
      if (event.onboardingTask.onboardingTaskId.isEmpty) {
        updated = await restClient.createOnboardingTask(
          onboardingTask: event.onboardingTask,
        );
      } else {
        updated = await restClient.updateOnboardingTask(
          onboardingTask: event.onboardingTask,
        );
      }
      final list = List<OnboardingTask>.from(state.onboardingTasks);
      final index = list.indexWhere(
        (e) => e.onboardingTaskId == updated.onboardingTaskId,
      );
      if (index >= 0) {
        list[index] = updated;
      } else {
        list.insert(0, updated);
      }
      emit(
        state.copyWith(
          status: OnboardingTaskStatus.success,
          onboardingTasks: list,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OnboardingTaskStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onOnboardingTaskDelete(
    OnboardingTaskDelete event,
    Emitter<OnboardingTaskState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OnboardingTaskStatus.loading));
      await restClient.deleteOnboardingTask(
        onboardingTask: event.onboardingTask,
      );
      final list = List<OnboardingTask>.from(state.onboardingTasks)
        ..removeWhere(
          (e) => e.onboardingTaskId == event.onboardingTask.onboardingTaskId,
        );
      emit(
        state.copyWith(
          status: OnboardingTaskStatus.success,
          onboardingTasks: list,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OnboardingTaskStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}

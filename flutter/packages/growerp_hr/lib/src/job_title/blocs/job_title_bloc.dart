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

part 'job_title_event.dart';
part 'job_title_state.dart';

const _throttleDuration = Duration(milliseconds: 100);
const _searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Search keystrokes are debounced and the running search is cancelled by the
/// next one: a dropping transformer would lose the last keystroke.
EventTransformer<JobTitleSearchChanged> _searchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.isNotEmpty)
        .debounce(_searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class JobTitleBloc extends Bloc<JobTitleEvent, JobTitleState> {
  final RestClient restClient;

  JobTitleBloc(this.restClient) : super(const JobTitleState()) {
    on<JobTitlesFetch>(
      _onJobTitlesFetch,
      transformer: _throttleDroppable(_throttleDuration),
    );
    on<JobTitleSearchChanged>(
      _onJobTitleSearchChanged,
      transformer: _searchDebounce(),
    );
    on<JobTitleUpdate>(_onJobTitleUpdate);
    on<JobTitleDelete>(_onJobTitleDelete);
  }

  Future<void> _onJobTitlesFetch(
    JobTitlesFetch event,
    Emitter<JobTitleState> emit,
  ) async {
    if (state.hasReachedMax &&
        !event.refresh &&
        event.searchString == state.searchString) {
      return;
    }
    try {
      emit(state.copyWith(status: JobTitleStatus.loading));
      if (event.refresh || event.searchString != state.searchString) {
        final result = await restClient.getJobTitles(
          search: event.searchString.isEmpty ? null : event.searchString,
          start: 0,
          limit: event.limit,
        );
        return emit(
          state.copyWith(
            status: JobTitleStatus.success,
            jobTitles: result.jobTitles,
            hasReachedMax: result.jobTitles.length < event.limit,
            searchString: event.searchString,
          ),
        );
      }
      final result = await restClient.getJobTitles(
        search: event.searchString.isEmpty ? null : event.searchString,
        start: state.jobTitles.length,
        limit: event.limit,
      );
      emit(
        result.jobTitles.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: JobTitleStatus.success,
                jobTitles: [...state.jobTitles, ...result.jobTitles],
                hasReachedMax: result.jobTitles.length < event.limit,
              ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: JobTitleStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onJobTitleSearchChanged(
    JobTitleSearchChanged event,
    Emitter<JobTitleState> emit,
  ) async {
    return _onJobTitlesFetch(
      JobTitlesFetch(refresh: true, searchString: event.searchString),
      emit,
    );
  }

  Future<void> _onJobTitleUpdate(
    JobTitleUpdate event,
    Emitter<JobTitleState> emit,
  ) async {
    try {
      emit(state.copyWith(status: JobTitleStatus.loading));
      JobTitle updated;
      if (event.jobTitle.jobTitleId.isEmpty) {
        updated = await restClient.createJobTitle(jobTitle: event.jobTitle);
      } else {
        updated = await restClient.updateJobTitle(jobTitle: event.jobTitle);
      }
      final list = List<JobTitle>.from(state.jobTitles);
      final index = list.indexWhere((e) => e.jobTitleId == updated.jobTitleId);
      if (index >= 0) {
        list[index] = updated;
      } else {
        list.insert(0, updated);
      }
      emit(state.copyWith(status: JobTitleStatus.success, jobTitles: list));
    } catch (e) {
      emit(
        state.copyWith(
          status: JobTitleStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onJobTitleDelete(
    JobTitleDelete event,
    Emitter<JobTitleState> emit,
  ) async {
    try {
      emit(state.copyWith(status: JobTitleStatus.loading));
      await restClient.deleteJobTitle(jobTitle: event.jobTitle);
      final list = List<JobTitle>.from(state.jobTitles)
        ..removeWhere((e) => e.jobTitleId == event.jobTitle.jobTitleId);
      emit(state.copyWith(status: JobTitleStatus.success, jobTitles: list));
    } catch (e) {
      emit(
        state.copyWith(
          status: JobTitleStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}

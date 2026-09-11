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

part 'department_event.dart';
part 'department_state.dart';

const _throttleDuration = Duration(milliseconds: 100);
const _searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Search keystrokes are debounced and the running search is cancelled by the
/// next one: a dropping transformer would lose the last keystroke.
EventTransformer<DepartmentSearchChanged> _searchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.isNotEmpty)
        .debounce(_searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class DepartmentBloc extends Bloc<DepartmentEvent, DepartmentState> {
  final RestClient restClient;

  DepartmentBloc(this.restClient) : super(const DepartmentState()) {
    on<DepartmentsFetch>(
      _onDepartmentsFetch,
      transformer: _throttleDroppable(_throttleDuration),
    );
    on<DepartmentSearchChanged>(
      _onDepartmentSearchChanged,
      transformer: _searchDebounce(),
    );
    on<DepartmentUpdate>(_onDepartmentUpdate);
    on<DepartmentDelete>(_onDepartmentDelete);
  }

  Future<void> _onDepartmentsFetch(
    DepartmentsFetch event,
    Emitter<DepartmentState> emit,
  ) async {
    if (state.hasReachedMax &&
        !event.refresh &&
        event.searchString == state.searchString) {
      return;
    }
    try {
      emit(state.copyWith(status: DepartmentStatus.loading));
      if (event.refresh || event.searchString != state.searchString) {
        final result = await restClient.getDepartments(
          search: event.searchString.isEmpty ? null : event.searchString,
          start: 0,
          limit: event.limit,
        );
        return emit(
          state.copyWith(
            status: DepartmentStatus.success,
            departments: result.departments,
            hasReachedMax: result.departments.length < event.limit,
            searchString: event.searchString,
          ),
        );
      }
      final result = await restClient.getDepartments(
        search: event.searchString.isEmpty ? null : event.searchString,
        start: state.departments.length,
        limit: event.limit,
      );
      emit(
        result.departments.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: DepartmentStatus.success,
                departments: [...state.departments, ...result.departments],
                hasReachedMax: result.departments.length < event.limit,
              ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DepartmentStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onDepartmentSearchChanged(
    DepartmentSearchChanged event,
    Emitter<DepartmentState> emit,
  ) async {
    return _onDepartmentsFetch(
      DepartmentsFetch(refresh: true, searchString: event.searchString),
      emit,
    );
  }

  Future<void> _onDepartmentUpdate(
    DepartmentUpdate event,
    Emitter<DepartmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DepartmentStatus.loading));
      Department updated;
      if (event.department.partyId.isEmpty) {
        updated = await restClient.createDepartment(
          department: event.department,
        );
      } else {
        updated = await restClient.updateDepartment(
          department: event.department,
        );
      }
      final list = List<Department>.from(state.departments);
      final index = list.indexWhere((e) => e.partyId == updated.partyId);
      if (index >= 0) {
        list[index] = updated;
      } else {
        list.insert(0, updated);
      }
      emit(state.copyWith(status: DepartmentStatus.success, departments: list));
    } catch (e) {
      emit(
        state.copyWith(
          status: DepartmentStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onDepartmentDelete(
    DepartmentDelete event,
    Emitter<DepartmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: DepartmentStatus.loading));
      await restClient.deleteDepartment(department: event.department);
      final list = List<Department>.from(state.departments)
        ..removeWhere((e) => e.partyId == event.department.partyId);
      emit(state.copyWith(status: DepartmentStatus.success, departments: list));
    } catch (e) {
      emit(
        state.copyWith(
          status: DepartmentStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}

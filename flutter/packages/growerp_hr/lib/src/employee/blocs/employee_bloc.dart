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

part 'employee_event.dart';
part 'employee_state.dart';

const _throttleDuration = Duration(milliseconds: 100);
const _searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Search keystrokes are debounced and the running search is cancelled by the
/// next one: a dropping transformer would lose the last keystroke.
EventTransformer<EmployeeSearchChanged> _searchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.isNotEmpty)
        .debounce(_searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final RestClient restClient;

  EmployeeBloc(this.restClient) : super(const EmployeeState()) {
    on<EmployeesFetch>(
      _onEmployeesFetch,
      transformer: _throttleDroppable(_throttleDuration),
    );
    on<EmployeeSearchChanged>(
      _onEmployeeSearchChanged,
      transformer: _searchDebounce(),
    );
    on<EmployeeUpdate>(_onEmployeeUpdate);
    on<EmployeeOnboardingTaskUpdate>(_onEmployeeOnboardingTaskUpdate);
  }

  Future<void> _onEmployeesFetch(
    EmployeesFetch event,
    Emitter<EmployeeState> emit,
  ) async {
    if (state.hasReachedMax &&
        !event.refresh &&
        event.searchString == state.searchString) {
      return;
    }
    try {
      emit(state.copyWith(status: EmployeeStatusBloc.loading));
      if (event.refresh || event.searchString != state.searchString) {
        final result = await restClient.getEmployees(
          partyId: event.partyId,
          search: event.searchString.isEmpty ? null : event.searchString,
          start: 0,
          limit: event.limit,
        );
        return emit(
          state.copyWith(
            status: EmployeeStatusBloc.success,
            employees: result.employees,
            hasReachedMax: result.employees.length < event.limit,
            searchString: event.searchString,
          ),
        );
      }
      final result = await restClient.getEmployees(
        partyId: event.partyId,
        search: event.searchString.isEmpty ? null : event.searchString,
        start: state.employees.length,
        limit: event.limit,
      );
      emit(
        result.employees.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: EmployeeStatusBloc.success,
                employees: [...state.employees, ...result.employees],
                hasReachedMax: result.employees.length < event.limit,
              ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onEmployeeSearchChanged(
    EmployeeSearchChanged event,
    Emitter<EmployeeState> emit,
  ) async {
    return _onEmployeesFetch(
      EmployeesFetch(
        refresh: true,
        searchString: event.searchString,
        partyId: event.partyId,
      ),
      emit,
    );
  }

  Future<void> _onEmployeeUpdate(
    EmployeeUpdate event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: EmployeeStatusBloc.loading));
      Employee updated;
      if (event.employee.partyId.isEmpty) {
        updated = await restClient.createEmployee(employee: event.employee);
      } else {
        updated = await restClient.updateEmployee(employee: event.employee);
      }
      emit(
        state.copyWith(
          status: EmployeeStatusBloc.success,
          employees: _replace(updated),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onEmployeeOnboardingTaskUpdate(
    EmployeeOnboardingTaskUpdate event,
    Emitter<EmployeeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: EmployeeStatusBloc.loading));
      final updated = await restClient.updateEmployeeOnboardingTask(
        partyId: event.partyId,
        onboardingTaskId: event.onboardingTaskId,
        completed: event.completed,
      );
      // a checklist change keeps the dialog open: own status
      emit(
        state.copyWith(
          status: EmployeeStatusBloc.checklistSuccess,
          employees: _replace(updated),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmployeeStatusBloc.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  List<Employee> _replace(Employee updated) {
    final list = List<Employee>.from(state.employees);
    final index = list.indexWhere((e) => e.partyId == updated.partyId);
    if (index >= 0) {
      list[index] = updated;
    } else {
      list.insert(0, updated);
    }
    return list;
  }
}

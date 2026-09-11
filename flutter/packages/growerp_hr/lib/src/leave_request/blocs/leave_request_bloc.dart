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
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'leave_request_event.dart';
part 'leave_request_state.dart';

const _throttleDuration = Duration(milliseconds: 100);
const _searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Search keystrokes are debounced and the running search is cancelled by the
/// next one: a dropping transformer would lose the last keystroke.
EventTransformer<LeaveRequestSearchChanged> _searchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.isNotEmpty)
        .debounce(_searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class LeaveRequestBloc extends Bloc<LeaveRequestEvent, LeaveRequestState> {
  final RestClient restClient;

  LeaveRequestBloc(this.restClient) : super(const LeaveRequestState()) {
    on<LeaveRequestsFetch>(
      _onLeaveRequestsFetch,
      transformer: _throttleDroppable(_throttleDuration),
    );
    on<LeaveRequestSearchChanged>(
      _onLeaveRequestSearchChanged,
      transformer: _searchDebounce(),
    );
    on<LeaveRequestUpdate>(_onLeaveRequestUpdate);
    on<LeaveRequestDelete>(_onLeaveRequestDelete);
    on<LeaveBalancesFetch>(_onLeaveBalancesFetch);
    on<LeaveAllowanceUpdate>(_onLeaveAllowanceUpdate);
  }

  Future<void> _onLeaveRequestsFetch(
    LeaveRequestsFetch event,
    Emitter<LeaveRequestState> emit,
  ) async {
    if (state.hasReachedMax &&
        !event.refresh &&
        event.searchString == state.searchString) {
      return;
    }
    try {
      emit(state.copyWith(status: LeaveRequestStatus.loading));
      if (event.refresh || event.searchString != state.searchString) {
        final result = await restClient.getLeaveRequests(
          partyId: event.partyId,
          statusId: event.leaveStatus?.value,
          search: event.searchString.isEmpty ? null : event.searchString,
          start: 0,
          limit: event.limit,
        );
        return emit(
          state.copyWith(
            status: LeaveRequestStatus.success,
            leaveRequests: result.leaveRequests,
            hasReachedMax: result.leaveRequests.length < event.limit,
            searchString: event.searchString,
          ),
        );
      }
      final result = await restClient.getLeaveRequests(
        partyId: event.partyId,
        statusId: event.leaveStatus?.value,
        search: event.searchString.isEmpty ? null : event.searchString,
        start: state.leaveRequests.length,
        limit: event.limit,
      );
      emit(
        result.leaveRequests.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: LeaveRequestStatus.success,
                leaveRequests: [
                  ...state.leaveRequests,
                  ...result.leaveRequests,
                ],
                hasReachedMax: result.leaveRequests.length < event.limit,
              ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LeaveRequestStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onLeaveRequestSearchChanged(
    LeaveRequestSearchChanged event,
    Emitter<LeaveRequestState> emit,
  ) async {
    return _onLeaveRequestsFetch(
      LeaveRequestsFetch(
        refresh: true,
        searchString: event.searchString,
        partyId: event.partyId,
      ),
      emit,
    );
  }

  Future<void> _onLeaveRequestUpdate(
    LeaveRequestUpdate event,
    Emitter<LeaveRequestState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LeaveRequestStatus.loading));
      LeaveRequest updated;
      if (event.leaveRequest.leaveRequestId.isEmpty) {
        updated = await restClient.createLeaveRequest(
          leaveRequest: event.leaveRequest,
        );
      } else {
        updated = await restClient.updateLeaveRequest(
          leaveRequest: event.leaveRequest,
        );
      }
      final list = List<LeaveRequest>.from(state.leaveRequests);
      final index = list.indexWhere(
        (l) => l.leaveRequestId == updated.leaveRequestId,
      );
      if (index >= 0) {
        list[index] = updated;
      } else {
        list.insert(0, updated);
      }
      emit(
        state.copyWith(status: LeaveRequestStatus.success, leaveRequests: list),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LeaveRequestStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onLeaveRequestDelete(
    LeaveRequestDelete event,
    Emitter<LeaveRequestState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LeaveRequestStatus.loading));
      await restClient.deleteLeaveRequest(leaveRequest: event.leaveRequest);
      final list = List<LeaveRequest>.from(state.leaveRequests)
        ..removeWhere(
          (l) => l.leaveRequestId == event.leaveRequest.leaveRequestId,
        );
      emit(
        state.copyWith(status: LeaveRequestStatus.success, leaveRequests: list),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LeaveRequestStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// balances use their own success status: an open request dialog closes on
  /// [LeaveRequestStatus.success] and a background balance fetch should not
  /// close it.
  Future<void> _onLeaveBalancesFetch(
    LeaveBalancesFetch event,
    Emitter<LeaveRequestState> emit,
  ) async {
    try {
      final result = await restClient.getLeaveAllowances(
        partyId: event.partyId,
        year: event.year,
      );
      emit(
        state.copyWith(
          status: LeaveRequestStatus.balancesSuccess,
          balances: result.leaveBalances,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LeaveRequestStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onLeaveAllowanceUpdate(
    LeaveAllowanceUpdate event,
    Emitter<LeaveRequestState> emit,
  ) async {
    try {
      final result = await restClient.updateLeaveAllowance(
        partyId: event.partyId,
        leaveTypeEnumId: event.leaveType.value,
        year: event.year,
        days: event.days.toString(),
      );
      emit(
        state.copyWith(
          status: LeaveRequestStatus.balancesSuccess,
          balances: result.leaveBalances,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LeaveRequestStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}

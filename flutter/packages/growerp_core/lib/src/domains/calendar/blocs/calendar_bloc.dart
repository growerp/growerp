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
import 'package:growerp_models/growerp_models.dart';

import '../../../services/get_dio_error.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

/// Loads the items of the period the in-app calendar shows.
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc(this.restClient) : super(const CalendarState()) {
    // a later period replaces an earlier one still loading
    on<CalendarFetch>(_onCalendarFetch, transformer: restartable());
  }

  final RestClient restClient;

  Future<void> _onCalendarFetch(
    CalendarFetch event,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(status: CalendarStatus.loading));
    try {
      final result = await restClient.getCalendarItems(
        fromDate: event.from.millisecondsSinceEpoch,
        thruDate: event.thru.millisecondsSinceEpoch,
        includeContent: event.includeContent,
      );
      emit(
        state.copyWith(
          status: CalendarStatus.success,
          items: result.calendarItems,
          calendarConnected: result.calendarConnected,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CalendarStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}

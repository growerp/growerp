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

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';

part 'communication_event.dart';
part 'communication_state.dart';

/// Communications of one person (userPseudoId) or of a company plus its
/// employees (companyPseudoId).
class CommunicationBloc
    extends Bloc<CommunicationBlocEvent, CommunicationState> {
  CommunicationBloc(this.restClient, {this.userPseudoId, this.companyPseudoId})
    : super(const CommunicationState()) {
    on<CommunicationFetch>(_onFetch, transformer: restartable());
    on<CommunicationUpdate>(_onUpdate);
    on<CommunicationDelete>(_onDelete);
  }

  final RestClient restClient;
  final String? userPseudoId;
  final String? companyPseudoId;
  static const _limit = 20;

  Future<void> _onFetch(
    CommunicationFetch event,
    Emitter<CommunicationState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh) return;
    final start = event.refresh ? 0 : state.communicationEvents.length;
    try {
      emit(state.copyWith(status: CommunicationStatus.loading));
      final result = await restClient.getCommunicationEvents(
        userPseudoId: userPseudoId,
        companyPseudoId: companyPseudoId,
        searchString: event.searchString.isEmpty ? null : event.searchString,
        start: start,
        limit: _limit,
      );
      emit(
        state.copyWith(
          status: CommunicationStatus.success,
          communicationEvents: start == 0
              ? result.communicationEvents
              : (List.of(state.communicationEvents)
                  ..addAll(result.communicationEvents)),
          hasReachedMax: result.communicationEvents.length < _limit,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CommunicationStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    CommunicationUpdate event,
    Emitter<CommunicationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CommunicationStatus.loading));
      final events = List.of(state.communicationEvents);
      if (event.communicationEvent.communicationEventId == null) {
        final result = await restClient.createCommunicationEvent(
          communicationEvent: event.communicationEvent,
        );
        events.insert(0, result);
        emit(
          state.copyWith(
            status: CommunicationStatus.success,
            communicationEvents: events,
            action: CommunicationAction.added,
          ),
        );
      } else {
        final result = await restClient.updateCommunicationEvent(
          communicationEvent: event.communicationEvent,
        );
        final index = events.indexWhere(
          (e) => e.communicationEventId == result.communicationEventId,
        );
        if (index >= 0) events[index] = result;
        emit(
          state.copyWith(
            status: CommunicationStatus.success,
            communicationEvents: events,
            action: CommunicationAction.updated,
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CommunicationStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onDelete(
    CommunicationDelete event,
    Emitter<CommunicationState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CommunicationStatus.loading));
      await restClient.deleteCommunicationEvent(
        communicationEvent: CommunicationEvent(
          communicationEventId: event.communicationEvent.communicationEventId,
        ),
      );
      emit(
        state.copyWith(
          status: CommunicationStatus.success,
          communicationEvents: List.of(state.communicationEvents)
            ..removeWhere(
              (e) =>
                  e.communicationEventId ==
                  event.communicationEvent.communicationEventId,
            ),
          action: CommunicationAction.deleted,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CommunicationStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}

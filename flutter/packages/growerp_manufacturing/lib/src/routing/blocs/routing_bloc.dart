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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:equatable/equatable.dart';

part 'routing_event.dart';
part 'routing_state.dart';

EventTransformer<E> routingDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class RoutingBloc extends Bloc<RoutingEvent, RoutingState> {
  RoutingBloc(this.restClient) : super(const RoutingState()) {
    on<RoutingsFetch>(
      _onRoutingsFetch,
      transformer: routingDroppable(const Duration(milliseconds: 100)),
    );
    on<RoutingUpdate>(_onRoutingUpdate);
    on<RoutingDelete>(_onRoutingDelete);
    on<RoutingTaskUpdate>(_onRoutingTaskUpdate);
    on<RoutingTaskDelete>(_onRoutingTaskDelete);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onRoutingsFetch(
    RoutingsFetch event,
    Emitter<RoutingState> emit,
  ) async {
    if (state.status == RoutingStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.routings.length;
    }
    try {
      emit(state.copyWith(status: RoutingStatus.loading));
      Routings compResult = await restClient.getRoutings(
        search: event.searchString,
        start: start,
        limit: event.limit,
      );
      return emit(
        state.copyWith(
          status: RoutingStatus.success,
          routings: start == 0
              ? compResult.routings
              : (List.of(state.routings)..addAll(compResult.routings)),
          hasReachedMax: compResult.routings.length < event.limit,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: RoutingStatus.failure,
          routings: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onRoutingUpdate(
    RoutingUpdate event,
    Emitter<RoutingState> emit,
  ) async {
    try {
      List<Routing> routings = List.from(state.routings);
      if (event.routing.routingId.isNotEmpty) {
        Routing compResult =
            await restClient.updateRouting(routing: event.routing);
        int index = routings.indexWhere(
          (e) => e.routingId == event.routing.routingId,
        );
        if (index >= 0) {
          routings[index] = compResult;
        } else {
          routings.insert(0, compResult);
        }
      } else {
        Routing compResult =
            await restClient.createRouting(routing: event.routing);
        routings.insert(0, compResult);
      }
      return emit(
        state.copyWith(status: RoutingStatus.success, routings: routings),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: RoutingStatus.failure,
          routings: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onRoutingDelete(
    RoutingDelete event,
    Emitter<RoutingState> emit,
  ) async {
    try {
      List<Routing> routings = List.from(state.routings);
      await restClient.deleteRouting(routing: event.routing);
      routings.removeWhere((e) => e.routingId == event.routing.routingId);
      return emit(
        state.copyWith(status: RoutingStatus.success, routings: routings),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: RoutingStatus.failure,
          routings: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onRoutingTaskUpdate(
    RoutingTaskUpdate event,
    Emitter<RoutingState> emit,
  ) async {
    try {
      if (event.routingTask.routingTaskId.isNotEmpty) {
        await restClient.updateRoutingTask(routingTask: event.routingTask);
      } else {
        await restClient.createRoutingTask(routingTask: event.routingTask);
      }
      // Refresh the routing list to get updated tasks
      add(RoutingsFetch(refresh: true));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: RoutingStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onRoutingTaskDelete(
    RoutingTaskDelete event,
    Emitter<RoutingState> emit,
  ) async {
    try {
      await restClient.deleteRoutingTask(routingTask: event.routingTask);
      add(RoutingsFetch(refresh: true));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: RoutingStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}

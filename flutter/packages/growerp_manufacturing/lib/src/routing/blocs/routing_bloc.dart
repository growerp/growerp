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

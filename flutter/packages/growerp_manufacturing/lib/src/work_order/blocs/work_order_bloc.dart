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

part 'work_order_event.dart';
part 'work_order_state.dart';

EventTransformer<E> workOrderDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class WorkOrderBloc extends Bloc<WorkOrderEvent, WorkOrderState> {
  WorkOrderBloc(this.restClient) : super(const WorkOrderState()) {
    on<WorkOrderFetch>(
      _onWorkOrderFetch,
      transformer: workOrderDroppable(const Duration(milliseconds: 100)),
    );
    on<WorkOrderUpdate>(_onWorkOrderUpdate);
    on<WorkOrderDelete>(_onWorkOrderDelete);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onWorkOrderFetch(
    WorkOrderFetch event,
    Emitter<WorkOrderState> emit,
  ) async {
    if (state.status == WorkOrderStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.workOrders.length;
    }
    try {
      emit(state.copyWith(status: WorkOrderStatus.loading));
      WorkOrders compResult = await restClient.getWorkOrder(
        search: event.searchString,
        start: start,
        limit: event.limit,
      );
      return emit(
        state.copyWith(
          status: WorkOrderStatus.success,
          workOrders: start == 0
              ? compResult.workOrders
              : (List.of(state.workOrders)..addAll(compResult.workOrders)),
          hasReachedMax: compResult.workOrders.length < event.limit,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WorkOrderStatus.failure,
          workOrders: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onWorkOrderUpdate(
    WorkOrderUpdate event,
    Emitter<WorkOrderState> emit,
  ) async {
    try {
      List<WorkOrder> workOrders = List.from(state.workOrders);
      if (event.workOrder.workEffortId.isNotEmpty) {
        WorkOrder compResult = await restClient.updateWorkOrder(
          workOrder: event.workOrder,
        );
        int index = workOrders.indexWhere(
          (e) => e.workEffortId == event.workOrder.workEffortId,
        );
        if (index >= 0) {
          workOrders[index] = compResult;
        } else {
          workOrders.insert(0, compResult);
        }
        return emit(
          state.copyWith(
            status: WorkOrderStatus.success,
            workOrders: workOrders,
          ),
        );
      } else {
        WorkOrder compResult = await restClient.createWorkOrder(
          workOrder: event.workOrder,
        );
        workOrders.insert(0, compResult);
        return emit(
          state.copyWith(
            status: WorkOrderStatus.success,
            workOrders: workOrders,
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WorkOrderStatus.failure,
          workOrders: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onWorkOrderDelete(
    WorkOrderDelete event,
    Emitter<WorkOrderState> emit,
  ) async {
    try {
      List<WorkOrder> workOrders = List.from(state.workOrders);
      await restClient.deleteWorkOrder(workOrder: event.workOrder);
      workOrders.removeWhere(
        (e) => e.workEffortId == event.workOrder.workEffortId,
      );
      return emit(
        state.copyWith(
          status: WorkOrderStatus.success,
          workOrders: workOrders,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WorkOrderStatus.failure,
          workOrders: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}

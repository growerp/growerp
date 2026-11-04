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
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

part 'pos_kitchen_event.dart';
part 'pos_kitchen_state.dart';

/// What the kitchen still has to do.
class PosKitchenBloc extends Bloc<PosKitchenEvent, PosKitchenState> {
  final RestClient restClient;

  PosKitchenBloc(this.restClient) : super(const PosKitchenState()) {
    on<PosKitchenFetch>(_onFetch, transformer: restartable());
    on<PosKitchenBump>(_onBump, transformer: sequential());
  }

  Future<void> _reload(Emitter<PosKitchenState> emit) async {
    final result = await restClient.getPosKitchen();
    emit(
      state.copyWith(status: PosKitchenStatus.success, tickets: result.tickets),
    );
  }

  Future<void> _failed(DioException e, Emitter<PosKitchenState> emit) async {
    emit(
      state.copyWith(
        status: PosKitchenStatus.failure,
        message: await getDioError(e),
      ),
    );
  }

  Future<void> _onFetch(
    PosKitchenFetch event,
    Emitter<PosKitchenState> emit,
  ) async {
    try {
      await _reload(emit);
    } on DioException catch (e) {
      await _failed(e, emit);
    }
  }

  /// One step on: a line sent is ready, a line ready is served.
  Future<void> _onBump(
    PosKitchenBump event,
    Emitter<PosKitchenState> emit,
  ) async {
    try {
      await restClient.updatePosKitchenLine(
        orderId: event.line.orderId!,
        orderItemSeqId: event.line.orderItemSeqId!,
        kitchenStatus: event.line.kitchenStatus == 'Sent' ? 'Ready' : 'Served',
      );
      await _reload(emit);
    } on DioException catch (e) {
      await _failed(e, emit);
    }
  }
}

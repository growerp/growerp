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

part 'pos_floor_event.dart';
part 'pos_floor_state.dart';

/// The tables of the restaurant and what goes on at them.
class PosFloorBloc extends Bloc<PosFloorEvent, PosFloorState> {
  final RestClient restClient;

  PosFloorBloc(this.restClient) : super(const PosFloorState()) {
    on<PosFloorFetch>(_onFetch, transformer: restartable());
    on<PosTableSave>(_onSave, transformer: sequential());
    on<PosTableDelete>(_onDelete, transformer: sequential());
  }

  Future<void> _reload(Emitter<PosFloorState> emit, {String? message}) async {
    final result = await restClient.getPosFloorPlan();
    emit(
      state.copyWith(
        status: PosFloorStatus.success,
        tables: result.tables,
        message: message,
      ),
    );
  }

  Future<void> _guarded(
    Emitter<PosFloorState> emit,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosFloorStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onFetch(PosFloorFetch event, Emitter<PosFloorState> emit) =>
      _guarded(emit, () => _reload(emit));

  Future<void> _onSave(PosTableSave event, Emitter<PosFloorState> emit) =>
      _guarded(emit, () async {
        if (event.table.assetId == null) {
          await restClient.createPosTable(table: event.table);
        } else {
          await restClient.updatePosTable(table: event.table);
        }
        await _reload(emit, message: 'saved');
      });

  Future<void> _onDelete(PosTableDelete event, Emitter<PosFloorState> emit) =>
      _guarded(emit, () async {
        await restClient.deletePosTable(assetId: event.assetId);
        await _reload(emit, message: 'saved');
      });
}

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
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

part 'pos_tab_event.dart';
part 'pos_tab_state.dart';

/// The tab on the screen. Every change comes back from the backend as the whole
/// tab. One event at a time, so lines cannot pass each other.
class PosTabBloc extends Bloc<PosTabEvent, PosTabState> {
  final RestClient restClient;

  PosTabBloc(this.restClient) : super(const PosTabState()) {
    on<PosTabEvent>(_onEvent, transformer: sequential());
  }

  String get _tabId => state.tab!.tabId!;

  Future<void> _onEvent(PosTabEvent event, Emitter<PosTabState> emit) async {
    // another table: the old bill must be gone before anything can be tapped
    emit(
      event is PosTabOpen
          ? const PosTabState(status: PosTabStatus.loading)
          : state.copyWith(status: PosTabStatus.loading),
    );
    try {
      switch (event) {
        case PosTabSplit():
          final result = await restClient.splitPosTab(
            tabId: _tabId,
            ways: event.ways,
            assignments: event.assignments,
          );
          emit(
            state.copyWith(status: PosTabStatus.split, shares: result.shares),
          );
        case PosTabCancel():
          await restClient.cancelPosTab(tabId: _tabId);
          emit(const PosTabState(status: PosTabStatus.closed));
        default:
          final tab = await _call(event);
          emit(state.copyWith(status: PosTabStatus.success, tab: tab));
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: PosTabStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<PosTab> _call(PosTabEvent event) => switch (event) {
    PosTabOpen() =>
      event.tabId != null
          ? restClient.getPosTab(tabId: event.tabId!)
          : restClient.openPosTab(tableAssetId: event.tableAssetId),
    PosTabAddLine() => restClient.addPosTabLine(
      tabId: _tabId,
      productId: event.productId,
      quantity: Decimal.one,
      modifierIds: event.modifierIds,
      note: event.note,
    ),
    PosTabChangeLine() => restClient.updatePosTabLine(
      tabId: _tabId,
      orderItemSeqId: event.orderItemSeqId,
      quantity: event.quantity,
    ),
    PosTabVoidLine() => restClient.voidPosTabLine(
      tabId: _tabId,
      orderItemSeqId: event.orderItemSeqId,
      reason: event.reason,
    ),
    PosTabSend() => restClient.sendPosTab(tabId: _tabId),
    PosTabMove() => restClient.movePosTab(
      tabId: _tabId,
      tableAssetId: event.tableAssetId,
    ),
    _ => throw UnsupportedError('$event'),
  };
}

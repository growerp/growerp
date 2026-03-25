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

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'liner_panel_event.dart';
part 'liner_panel_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class LinerPanelBloc extends Bloc<LinerPanelEvent, LinerPanelState> {
  final RestClient restClient;

  LinerPanelBloc(this.restClient) : super(const LinerPanelState()) {
    on<LinerPanelsFetch>(_onLinerPanelsFetch,
        transformer: _throttleDroppable(_throttleDuration));
    on<LinerPanelUpdate>(_onLinerPanelUpdate);
    on<LinerPanelDelete>(_onLinerPanelDelete);
  }

  Future<void> _onLinerPanelsFetch(
    LinerPanelsFetch event,
    Emitter<LinerPanelState> emit,
  ) async {
    final sameFilter = event.workEffortId == state.workEffortId &&
        event.salesOrderId == state.salesOrderId;
    if (state.hasReachedMax && !event.refresh && sameFilter) return;
    try {
      emit(state.copyWith(status: LinerPanelStatus.loading));
      if (event.refresh || !sameFilter) {
        final result = await restClient.getLinerPanels(
          workEffortId: event.workEffortId,
          salesOrderId: event.salesOrderId,
          start: 0,
          limit: event.limit,
        );
        return emit(state.copyWith(
          status: LinerPanelStatus.success,
          linerPanels: result.linerPanels,
          hasReachedMax: result.linerPanels.length < event.limit,
          workEffortId: event.workEffortId,
          salesOrderId: event.salesOrderId,
        ));
      }
      final result = await restClient.getLinerPanels(
        workEffortId: event.workEffortId,
        salesOrderId: event.salesOrderId,
        start: state.linerPanels.length,
        limit: event.limit,
      );
      emit(result.linerPanels.isEmpty
          ? state.copyWith(hasReachedMax: true)
          : state.copyWith(
              status: LinerPanelStatus.success,
              linerPanels: [...state.linerPanels, ...result.linerPanels],
              hasReachedMax: result.linerPanels.length < event.limit,
            ));
    } catch (e) {
      emit(state.copyWith(
          status: LinerPanelStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLinerPanelUpdate(
    LinerPanelUpdate event,
    Emitter<LinerPanelState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LinerPanelStatus.loading));
      LinerPanel updated;
      if (event.linerPanel.qcNum.isEmpty) {
        updated =
            await restClient.createLinerPanel(linerPanel: event.linerPanel);
      } else {
        updated =
            await restClient.updateLinerPanel(linerPanel: event.linerPanel);
      }
      final list = List<LinerPanel>.from(state.linerPanels);
      final index = list.indexWhere((p) => p.qcNum == updated.qcNum);
      if (index >= 0) {
        list[index] = updated;
      } else {
        list.add(updated);
      }
      emit(state.copyWith(
          status: LinerPanelStatus.success, linerPanels: list));
    } catch (e) {
      emit(state.copyWith(
          status: LinerPanelStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLinerPanelDelete(
    LinerPanelDelete event,
    Emitter<LinerPanelState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LinerPanelStatus.loading));
      await restClient.deleteLinerPanel(linerPanel: event.linerPanel);
      final list = List<LinerPanel>.from(state.linerPanels)
        ..removeWhere((p) => p.qcNum == event.linerPanel.qcNum);
      emit(state.copyWith(
          status: LinerPanelStatus.success, linerPanels: list));
    } catch (e) {
      emit(state.copyWith(
          status: LinerPanelStatus.failure, message: e.toString()));
    }
  }
}

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

part 'liner_type_event.dart';
part 'liner_type_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class LinerTypeBloc extends Bloc<LinerTypeEvent, LinerTypeState> {
  final RestClient restClient;

  LinerTypeBloc(this.restClient) : super(const LinerTypeState()) {
    on<LinerTypesFetch>(_onLinerTypesFetch,
        transformer: _throttleDroppable(_throttleDuration));
    on<LinerTypeUpdate>(_onLinerTypeUpdate);
    on<LinerTypeDelete>(_onLinerTypeDelete);
  }

  Future<void> _onLinerTypesFetch(
    LinerTypesFetch event,
    Emitter<LinerTypeState> emit,
  ) async {
    if (state.hasReachedMax &&
        !event.refresh &&
        event.searchString == state.searchString) {
      return;
    }
    try {
      emit(state.copyWith(status: LinerTypeStatus.loading));
      if (event.refresh || event.searchString != state.searchString) {
        final result = await restClient.getLinerTypes(
          search: event.searchString.isEmpty ? null : event.searchString,
          start: 0,
          limit: event.limit,
        );
        return emit(state.copyWith(
          status: LinerTypeStatus.success,
          linerTypes: result.linerTypes,
          hasReachedMax: result.linerTypes.length < event.limit,
          searchString: event.searchString,
        ));
      }
      final result = await restClient.getLinerTypes(
        search: event.searchString.isEmpty ? null : event.searchString,
        start: state.linerTypes.length,
        limit: event.limit,
      );
      emit(result.linerTypes.isEmpty
          ? state.copyWith(hasReachedMax: true)
          : state.copyWith(
              status: LinerTypeStatus.success,
              linerTypes: [...state.linerTypes, ...result.linerTypes],
              hasReachedMax: result.linerTypes.length < event.limit,
            ));
    } catch (e) {
      emit(state.copyWith(
          status: LinerTypeStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLinerTypeUpdate(
    LinerTypeUpdate event,
    Emitter<LinerTypeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LinerTypeStatus.loading));
      LinerType updated;
      if (event.linerType.linerTypeId.isEmpty) {
        updated = await restClient.createLinerType(linerType: event.linerType);
      } else {
        updated = await restClient.updateLinerType(linerType: event.linerType);
      }
      final list = List<LinerType>.from(state.linerTypes);
      final index =
          list.indexWhere((l) => l.linerTypeId == updated.linerTypeId);
      if (index >= 0) {
        list[index] = updated;
      } else {
        list.insert(0, updated);
      }
      emit(state.copyWith(
          status: LinerTypeStatus.success, linerTypes: list));
    } catch (e) {
      emit(state.copyWith(
          status: LinerTypeStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLinerTypeDelete(
    LinerTypeDelete event,
    Emitter<LinerTypeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LinerTypeStatus.loading));
      await restClient.deleteLinerType(linerType: event.linerType);
      final list = List<LinerType>.from(state.linerTypes)
        ..removeWhere((l) => l.linerTypeId == event.linerType.linerTypeId);
      emit(state.copyWith(
          status: LinerTypeStatus.success, linerTypes: list));
    } catch (e) {
      emit(state.copyWith(
          status: LinerTypeStatus.failure, message: e.toString()));
    }
  }
}

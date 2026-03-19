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

part 'bom_event.dart';
part 'bom_state.dart';

EventTransformer<E> bomDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class BomBloc extends Bloc<BomEvent, BomState> {
  BomBloc(this.restClient) : super(const BomState()) {
    on<BomsFetch>(
      _onBomsFetch,
      transformer: bomDroppable(const Duration(milliseconds: 100)),
    );
    on<BomFetch>(
      _onBomFetch,
      transformer: bomDroppable(const Duration(milliseconds: 100)),
    );
    on<BomUpdate>(_onBomUpdate);
    on<BomDelete>(_onBomDelete);
  }

  final RestClient restClient;

  Future<void> _onBomsFetch(
    BomsFetch event,
    Emitter<BomState> emit,
  ) async {
    final int start = (state.status == BomStatus.initial ||
            event.refresh ||
            event.searchString != '')
        ? 0
        : state.boms.length;
    try {
      emit(state.copyWith(status: BomStatus.loading));
      Boms result = await restClient.getBoms(
        search: event.searchString.isEmpty ? null : event.searchString,
        start: start,
        limit: event.limit,
      );
      return emit(
        state.copyWith(
          status: BomStatus.success,
          productId: null,
          boms: start == 0
              ? result.boms
              : (List.of(state.boms)..addAll(result.boms)),
          hasReachedMax: result.boms.length < event.limit,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: BomStatus.failure,
          boms: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onBomFetch(
    BomFetch event,
    Emitter<BomState> emit,
  ) async {
    final int start = (state.status == BomStatus.initial ||
            event.refresh ||
            event.searchString != '' ||
            event.productId != state.productId)
        ? 0
        : state.bomItems.length;
    try {
      emit(state.copyWith(status: BomStatus.loading));
      BomItems compResult = await restClient.getBomItem(
        productId: event.productId,
        search: event.searchString,
        start: start,
        limit: event.limit,
      );
      return emit(
        state.copyWith(
          status: BomStatus.success,
          productId: event.productId,
          bomItems: start == 0
              ? compResult.bomItems
              : (List.of(state.bomItems)..addAll(compResult.bomItems)),
          hasReachedMax: compResult.bomItems.length < event.limit,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: BomStatus.failure,
          bomItems: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onBomUpdate(
    BomUpdate event,
    Emitter<BomState> emit,
  ) async {
    try {
      List<BomItem> bomItems = List.from(state.bomItems);
      if (event.bomItem.fromDate != null && event.bomItem.fromDate!.isNotEmpty) {
        // update existing
        BomItem compResult = await restClient.updateBomItem(
          bomItem: event.bomItem,
        );
        int index = bomItems.indexWhere(
          (e) => e.toProductId == event.bomItem.toProductId,
        );
        if (index >= 0) {
          bomItems[index] = compResult;
        } else {
          bomItems.insert(0, compResult);
        }
        return emit(
          state.copyWith(status: BomStatus.success, bomItems: bomItems),
        );
      } else {
        // create new
        BomItem compResult = await restClient.createBomItem(
          bomItem: event.bomItem,
        );
        bomItems.insert(0, compResult);
        return emit(
          state.copyWith(status: BomStatus.success, bomItems: bomItems),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: BomStatus.failure,
          bomItems: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onBomDelete(
    BomDelete event,
    Emitter<BomState> emit,
  ) async {
    try {
      List<BomItem> bomItems = List.from(state.bomItems);
      await restClient.deleteBomItem(bomItem: event.bomItem);
      bomItems.removeWhere((e) => e.toProductId == event.bomItem.toProductId);
      return emit(
        state.copyWith(status: BomStatus.success, bomItems: bomItems),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: BomStatus.failure,
          bomItems: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}

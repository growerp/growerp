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
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';

part 'asset_event.dart';
part 'asset_state.dart';

const _assetLimit = 20;
const searchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> assetDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

EventTransformer<AssetSearchChanged> assetSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(searchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  AssetBloc(this.restClient, this.applicationId)
    : super(const AssetState()) {
    on<AssetFetch>(
      _onAssetFetch,
      transformer: assetDroppable(const Duration(milliseconds: 100)),
    );
    on<AssetUpdate>(_onAssetUpdate);
    on<AssetSearchChanged>(
      _onAssetSearchChanged,
      transformer: assetSearchDebounce(),
    );
  }

  final RestClient restClient;
  final String applicationId;

  Future<void> _onAssetFetch(AssetFetch event, Emitter<AssetState> emit) async {
    try {
      if (state.status == AssetStatus.initial ||
          event.refresh ||
          event.searchString != '') {
        emit(
          state.copyWith(
            status: AssetStatus.loading,
            assets: [],
            hasReachedMax: false,
          ),
        );
      } else {
        emit(state.copyWith(status: AssetStatus.loading));
      }
      Assets compResult = await restClient.getAsset(
        searchString: event.searchString,
        assetClassId: event.assetClassId,
      );
      emit(
        state.copyWith(
          status: AssetStatus.success,
          assets: state.assets..addAll(compResult.assets),
          hasReachedMax: compResult.assets.length < _assetLimit ? true : false,
          searchString: event.searchString,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AssetStatus.failure,
          assets: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onAssetSearchChanged(
    AssetSearchChanged event,
    Emitter<AssetState> emit,
  ) async {
    return _onAssetFetch(
      AssetFetch(
        searchString: event.searchString,
        refresh: true,
        assetClassId: event.assetClassId,
      ),
      emit,
    );
  }

  Future<void> _onAssetUpdate(
    AssetUpdate event,
    Emitter<AssetState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AssetStatus.loading));
      List<Asset> assets = List.from(state.assets);
      if (event.asset.assetId.isNotEmpty) {
        // update
        Asset compResult = await restClient.updateAsset(
          asset: event.asset,
          applicationId: applicationId,
        );
        int index = assets.indexWhere(
          (element) => element.assetId == event.asset.assetId,
        );
        assets[index] = compResult;
        emit(
          state.copyWith(
            status: AssetStatus.success,
            assets: assets,
            message: 'assetUpdateSuccess:${event.asset.assetName}',
          ),
        );
      } else {
        // add
        Asset compResult = await restClient.createAsset(
          asset: event.asset,
          applicationId: applicationId,
        );
        assets.insert(0, compResult);
        emit(
          state.copyWith(
            status: AssetStatus.success,
            assets: assets,
            message: 'assetAddSuccess:${event.asset.assetName}',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AssetStatus.failure,
          assets: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}

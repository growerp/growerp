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
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

part 'asset_event.dart';
part 'asset_state.dart';

const _assetLimit = 20;

EventTransformer<E> assetDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  AssetBloc(
    this.restClient,
    this.classificationId,
  ) : super(const AssetState()) {
    on<AssetFetch>(_onAssetFetch,
        transformer: assetDroppable(const Duration(milliseconds: 100)));
    on<AssetUpdate>(_onAssetUpdate);
  }

  final RestClient restClient;
  final String classificationId;

  Future<void> _onAssetFetch(
    AssetFetch event,
    Emitter<AssetState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    try {
      emit(state.copyWith(status: AssetStatus.loading));
      Assets compResult = await restClient.getAsset(
          searchString: event.searchString, assetClassId: event.assetClassId);
      emit(state.copyWith(
        status: AssetStatus.success,
        assets: compResult.assets,
        hasReachedMax: compResult.assets.length < _assetLimit ? true : false,
        searchString: event.searchString,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: AssetStatus.failure, assets: [], message: getDioError(e)));
    }
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
            asset: event.asset, classificationId: classificationId);
        int index = assets
            .indexWhere((element) => element.assetId == event.asset.assetId);
        assets[index] = compResult;
        emit(state.copyWith(
            status: AssetStatus.success,
            assets: assets,
            message: "Asset ${event.asset.assetName} updated"));
      } else {
        // add
        Asset compResult = await restClient.createAsset(
            asset: event.asset, classificationId: classificationId);
        assets.insert(0, compResult);
        emit(state.copyWith(
            status: AssetStatus.success,
            assets: assets,
            message: "Asset ${event.asset.assetName} added"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: AssetStatus.failure, assets: [], message: getDioError(e)));
    }
  }
}

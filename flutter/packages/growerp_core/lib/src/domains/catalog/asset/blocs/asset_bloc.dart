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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:equatable/equatable.dart';
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
  AssetBloc(this.repos) : super(const AssetState()) {
    on<AssetFetch>(_onAssetFetch,
        transformer: assetDroppable(const Duration(milliseconds: 100)));
    on<AssetUpdate>(_onAssetUpdate);
    on<AssetDelete>(_onAssetDelete);
  }

  final CatalogAPIRepository repos;

  Future<void> _onAssetFetch(
    AssetFetch event,
    Emitter<AssetState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    // start from record zero for initial and refresh
    emit(state.copyWith(status: AssetStatus.loading));
    if (state.status == AssetStatus.initial || event.refresh) {
      ApiResult<List<Asset>> compResult = await repos.getAsset(
          searchString: event.searchString, assetClassId: event.assetClassId);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: AssetStatus.success,
                assets: data,
                hasReachedMax: data.length < _assetLimit ? true : false,
                searchString: '',
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: AssetStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<Asset>> compResult = await repos.getAsset(
          searchString: event.searchString, assetClassId: event.assetClassId);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: AssetStatus.success,
                assets: data,
                hasReachedMax: data.length < _assetLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: AssetStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search
    ApiResult<List<Asset>> compResult = await repos.getAsset(
        searchString: event.searchString, assetClassId: event.assetClassId);
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: AssetStatus.success,
              assets: List.of(state.assets)..addAll(data),
              hasReachedMax: data.length < _assetLimit ? true : false,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: AssetStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onAssetUpdate(
    AssetUpdate event,
    Emitter<AssetState> emit,
  ) async {
    emit(state.copyWith(status: AssetStatus.loading));
    List<Asset> assets = List.from(state.assets);
    if (event.asset.assetId.isNotEmpty) {
      ApiResult<Asset> compResult = await repos.updateAsset(event.asset);
      return emit(compResult.when(
          success: (data) {
            int index = assets.indexWhere(
                (element) => element.assetId == event.asset.assetId);
            assets[index] = data;
            return state.copyWith(
                status: AssetStatus.success,
                assets: assets,
                message: "Asset ${event.asset.assetName} updated");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: AssetStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } else {
      // add
      ApiResult<Asset> compResult = await repos.createAsset(event.asset);
      return emit(compResult.when(
          success: (data) {
            assets.insert(0, data);
            return state.copyWith(
                status: AssetStatus.success,
                assets: assets,
                message: "Asset ${event.asset.assetName} added");
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: AssetStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
  }

  Future<void> _onAssetDelete(
    AssetDelete event,
    Emitter<AssetState> emit,
  ) async {
    emit(state.copyWith(status: AssetStatus.loading));
    List<Asset> assets = List.from(state.assets);
    ApiResult<Asset> compResult = await repos.deleteAsset(event.asset);
    return emit(compResult.when(
        success: (data) {
          int index = assets
              .indexWhere((element) => element.assetId == event.asset.assetId);
          assets.removeAt(index);
          return state.copyWith(
              status: AssetStatus.success,
              assets: assets,
              message: "Asset ${event.asset.assetName} deleted");
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: AssetStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }
}

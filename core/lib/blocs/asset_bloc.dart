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
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:models/@models.dart';
import 'package:rxdart/rxdart.dart';

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  final repos;
  List<Asset> assets = [];

  AssetBloc(
    this.repos,
  ) : super(AssetInitial());

  String classificationId =
      GlobalConfiguration().getValue<String>("classificationId");

  @override
  Stream<Transition<AssetEvent, AssetState>> transformEvents(
    Stream<AssetEvent> events,
    TransitionFunction<AssetEvent, AssetState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  Stream<AssetState> getAssets(
      {required dynamic event,
      final List<GanntLine> ganntLines = const <GanntLine>[],
      List<Asset> assets = const <Asset>[],
      int start = 0,
      String? searchString}) async* {
    dynamic result = await repos.getAsset(
        start: start,
        limit: event.limit,
        assetClassId: classificationId == 'AppHotel' ? 'Hotel Room' : null,
        search: searchString);
    if (result is List<Asset>) {
      yield AssetSuccess(
          ganntLines: ganntLines,
          assets: assets + result,
          search: searchString,
          hasReachedMax: result.length < event.limit ? true : false);
    } else
      yield AssetProblem(result);
  }

  @override
  Stream<AssetState> mapEventToState(AssetEvent event) async* {
    final AssetState currentState = state;
    if (event is FetchAsset) {
      if (event.refresh || currentState is AssetInitial) {
        yield* getAssets(
            event: event,
            searchString:
                currentState is AssetSuccess ? currentState.search : null);
      } else if (currentState is AssetSuccess) {
        // if we need to search
        if (event.search != null && currentState.search == null ||
            (currentState.search != null &&
                event.search != currentState.search)) {
          yield* getAssets(
              event: event,
              assets: currentState.assets,
              searchString: event.search);
        } else if (!_hasReachedMax(currentState)) {
          // get next page
          yield* getAssets(
              event: event,
              assets: currentState.assets,
              start: currentState.assets.length);
        }
      }
    } else if (event is UpdateAsset) {
      bool adding = event.asset.assetId == null;
      yield AssetLoading((adding ? 'adding' : 'updating') + ' ${event.asset}');
      dynamic result = await repos.updateAsset(event.asset);
      if (currentState is AssetSuccess) {
        if (result is Asset) {
          if (adding) {
            currentState.assets.add(result);
          } else {
            int index = currentState.assets
                .indexWhere((prod) => prod.assetId == result.assetId);
            currentState.assets[index] = result;
          }
          yield currentState.copyWith(
              message: 'asset ${result.assetName}[${result.assetId}] ' +
                  (adding ? ' added' : 'updated'));
        } else {
          yield AssetProblem(result);
        }
      }
    } else if (event is DeleteAsset) {
      yield AssetLoading(('deleting asset ${event.asset.assetName}'));
      dynamic result = await repos.deleteAsset(event.asset.assetId);
      if (currentState is AssetSuccess) {
        if (result is String && result == event.asset.assetId) {
          int index =
              currentState.assets.indexWhere((prod) => prod.assetId == result);
          currentState.assets.removeAt(index);
          yield currentState.copyWith(
              message: 'Asset ${event.asset.assetName} deleted');
        } else {
          yield AssetProblem(result);
        }
      }
    } else
      print("===Event $event not found");
  }
}

bool _hasReachedMax(AssetState state) =>
    state is AssetSuccess && state.hasReachedMax;

//#######################events###########################
abstract class AssetEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchAsset extends AssetEvent {
  final bool refresh;
  final int limit;
  final search;
  FetchAsset({this.refresh = false, this.limit = 20, this.search});
  @override
  String toString() =>
      "FetchAsset refresh: $refresh limit: $limit, search: $search";
}

class DeleteAsset extends AssetEvent {
  final Asset asset;
  DeleteAsset(this.asset);
  @override
  String toString() => "DeleteAsset: $asset";
}

class UpdateAsset extends AssetEvent {
  final Asset asset;
  UpdateAsset(this.asset);
  @override
  String toString() => "UpdateAsset: $asset";
}

//#######################state############################
abstract class AssetState extends Equatable {
  const AssetState();
  @override
  List<Object?> get props => [];
}

class AssetInitial extends AssetState {}

class AssetLoading extends AssetState {
  final String? message;
  AssetLoading([this.message]);
  @override
  List<Object?> get props => [message];
  @override
  String toString() => 'Asset loading...';
}

class AssetProblem extends AssetState {
  final String? errorMessage;
  AssetProblem(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
  @override
  String toString() => 'AssetProblem { errorMessage $errorMessage }';
}

class AssetSuccess extends AssetState {
  final List<GanntLine> ganntLines;
  final List<Asset> assets;
  final bool hasReachedMax;
  final String? message;
  final String? search;

  const AssetSuccess(
      {required this.ganntLines,
      required this.assets,
      required this.hasReachedMax,
      this.message,
      this.search});

  AssetSuccess copyWith({
    List<GanntLine>? ganntLines,
    List<Asset>? assets,
    bool? hasReachedMax,
    String? message,
    String? search,
  }) =>
      AssetSuccess(
        ganntLines: ganntLines ?? this.ganntLines,
        assets: assets ?? this.assets,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        message: message ?? this.message,
        search: search ?? this.search,
      );

  @override
  List<Object?> get props => [assets, hasReachedMax];

  @override
  String toString() => 'AssetSuccess { #assets: ${assets.length}, '
      'hasReachedMax: $hasReachedMax }';
}

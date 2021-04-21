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
  List<Asset>? assets;

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

  @override
  Stream<AssetState> mapEventToState(AssetEvent event) async* {
    final AssetState currentState = state;
    if (event is FetchAsset) {
      if (currentState is AssetInitial) {
        dynamic result = await repos.getAsset(
            start: 0,
            limit: event.limit,
            assetClassId: classificationId == 'AppHotel'
                ? assetClassIds['Hotel Room']
                : null,
            companyPartyId: event.companyPartyId,
            search: event.search);
        if (result is List<Asset>) {
          assets = result;
          yield AssetSuccess(
              assets: result,
              hasReachedMax: result.length < event.limit ? true : false);
        } else
          yield AssetProblem(result);
        return;
      } else if (currentState is AssetSuccess) {
        if (event.search != null && currentState.search == null ||
            (currentState.search != null &&
                event.search != currentState.search)) {
          yield AssetLoading();
          dynamic result = await repos.getAsset(
              start: 0,
              limit: event.limit,
              assetClassId: classificationId == 'AppHotel'
                  ? assetClassIds['Hotel Room']
                  : null,
              companyPartyId: event.companyPartyId,
              search: event.search);
          if (result is List<Asset>) {
            assets = result;
            yield AssetSuccess(
                assets: result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield AssetProblem(result);
          return;
        } else if (!_hasReachedMax(currentState)) {
          dynamic result = await repos.getAsset(
              start: currentState.assets!.length,
              limit: event.limit,
              search: event.search,
              companyPartyId: event.companyPartyId);
          if (result is List<Asset>) {
            yield currentState.copyWith(
                assets: currentState.assets! + result,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield AssetProblem(result);
        }
      }
    } else if (event is UpdateAsset) {
      bool adding = event.asset.assetId == null;
      yield AssetLoading(
          (adding ? 'adding' : 'updating') + ' asset ${event.asset.assetName}');
      dynamic result = await repos.updateAsset(event.asset);
      if (currentState is AssetSuccess) {
        if (result is Asset) {
          if (adding) {
            currentState.assets?.add(result);
          } else {
            int index = currentState.assets!
                .indexWhere((prod) => prod.assetId == result.assetId);
            currentState.assets!.replaceRange(index, index + 1, [result]);
          }
          yield AssetSuccess(
              assets: currentState.assets,
              hasReachedMax: _hasReachedMax(currentState),
              message: 'asset ${result.assetName}[${result.assetId}] ' +
                  (adding ? ' added' : 'updated'));
        } else {
          yield AssetProblem(result);
        }
      }
    } else if (event is DeleteAsset) {
      if (currentState is AssetSuccess) {
        int index = currentState.assets!
            .indexWhere((prod) => prod.assetId == event.asset.assetId);
        String? name = currentState.assets![index].assetName;
        yield AssetLoading('deleting asset $name');
        dynamic result = await repos.deleteAsset(event.asset.assetId);
        if (result == event.asset.assetId) {
          currentState.assets!.removeAt(index);
          yield AssetSuccess(
                  assets: currentState.assets,
                  hasReachedMax: _hasReachedMax(currentState))
              .copyWith(message: 'Asset $name deleted');
        } else {
          yield AssetProblem(result);
        }
      }
    } else
      print("===Event $event not found");
  }
}

bool _hasReachedMax(AssetState state) =>
    state is AssetSuccess && state.hasReachedMax!;

//#######################events###########################
abstract class AssetEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchAsset extends AssetEvent {
  final String? companyPartyId;
  final String? categoryId;
  final int limit;
  final search;
  FetchAsset(
      {this.companyPartyId, this.categoryId, this.limit = 20, this.search});
  @override
  String toString() => "FetchAsset company: $companyPartyId, "
      "limit: $limit, search: $search";
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
  final List<GanntLine>? ganntLines;
  final List<Asset>? assets;
  final bool? hasReachedMax;
  final String? message;
  final String? search;

  const AssetSuccess(
      {this.ganntLines,
      this.assets,
      this.hasReachedMax,
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
  String toString() => 'AssetSuccess { #assets: ${assets?.length}, '
      'hasReachedMax: $hasReachedMax }';
}

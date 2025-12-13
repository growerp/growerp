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

part 'location_event.dart';
part 'location_state.dart';

EventTransformer<E> locationDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc(this.restClient) : super(const LocationState()) {
    on<LocationFetch>(_onLocationFetch,
        transformer: locationDroppable(const Duration(milliseconds: 100)));
    on<LocationUpdate>(_onLocationUpdate);
    on<LocationDelete>(_onLocationDelete);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onLocationFetch(
    LocationFetch event,
    Emitter<LocationState> emit,
  ) async {
    if (state.status == LocationStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
    } else {
      start = state.locations.length;
    }
    try {
      // start from record zero for initial and refresh
      emit(state.copyWith(status: LocationStatus.loading));

      Locations compResult = await restClient.getLocation(
          start: start, searchString: event.searchString, limit: event.limit);

      return emit(state.copyWith(
        status: LocationStatus.success,
        locations: start == 0
            ? compResult.locations
            : (List.of(state.locations)..addAll(compResult.locations)),
        hasReachedMax: compResult.locations.length < event.limit ? true : false,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: LocationStatus.failure,
          locations: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onLocationUpdate(
    LocationUpdate event,
    Emitter<LocationState> emit,
  ) async {
    try {
      List<Location> locations = List.from(state.locations);
      if (event.location.locationId != null) {
        Location compResult =
            await restClient.updateLocation(location: event.location);
        int index = locations.indexWhere(
            (element) => element.locationId == event.location.locationId);
        locations[index] = compResult;
        return emit(state.copyWith(
            status: LocationStatus.success, locations: locations));
      } else {
        // add
        Location compResult =
            await restClient.createLocation(location: event.location);
        locations.insert(0, compResult);
        return emit(state.copyWith(
            status: LocationStatus.success, locations: locations));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: LocationStatus.failure,
          locations: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onLocationDelete(
    LocationDelete event,
    Emitter<LocationState> emit,
  ) async {
    try {
      List<Location> locations = List.from(state.locations);
      await restClient.deleteLocation(location: event.location);
      int index = locations.indexWhere(
          (element) => element.locationId == event.location.locationId);
      locations.removeAt(index);
      return emit(
          state.copyWith(status: LocationStatus.success, locations: locations));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: LocationStatus.failure,
          locations: [],
          message: await getDioError(e)));
    }
  }
}

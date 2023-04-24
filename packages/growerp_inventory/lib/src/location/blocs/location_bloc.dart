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
import 'package:stream_transform/stream_transform.dart';
import 'package:equatable/equatable.dart';
import '../../api_repository.dart';

part 'location_event.dart';
part 'location_state.dart';

const _locationLimit = 20;

EventTransformer<E> locationDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc(this.repos) : super(const LocationState()) {
    on<LocationFetch>(_onLocationFetch,
        transformer: locationDroppable(const Duration(milliseconds: 100)));
    on<LocationUpdate>(_onLocationUpdate);
    on<LocationDelete>(_onLocationDelete);
  }

  final InventoryAPIRepository repos;
  Future<void> _onLocationFetch(
    LocationFetch event,
    Emitter<LocationState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    // start from record zero for initial and refresh
    if (state.status == LocationStatus.initial || event.refresh) {
      ApiResult<List<Location>> compResult =
          await repos.getLocation(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: LocationStatus.success,
                locations: data,
                hasReachedMax: data.length < _locationLimit ? true : false,
                searchString: '',
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: LocationStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<Location>> compResult =
          await repos.getLocation(searchString: event.searchString);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: LocationStatus.success,
                locations: data,
                hasReachedMax: data.length < _locationLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: LocationStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search

    ApiResult<List<Location>> compResult =
        await repos.getLocation(searchString: event.searchString);
    return emit(compResult.when(
        success: (data) => state.copyWith(
              status: LocationStatus.success,
              locations: List.of(state.locations)..addAll(data),
              hasReachedMax: data.length < _locationLimit ? true : false,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: LocationStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onLocationUpdate(
    LocationUpdate event,
    Emitter<LocationState> emit,
  ) async {
    List<Location> locations = List.from(state.locations);
    if (event.location.locationId != null) {
      ApiResult<Location> compResult =
          await repos.updateLocation(event.location);
      return emit(compResult.when(
          success: (data) {
            int index = locations.indexWhere(
                (element) => element.locationId == event.location.locationId);
            locations[index] = data;
            return state.copyWith(
                status: LocationStatus.success, locations: locations);
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: LocationStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } else {
      // add
      ApiResult<Location> compResult =
          await repos.createLocation(event.location);
      return emit(compResult.when(
          success: (data) {
            locations.insert(0, data);
            return state.copyWith(
                status: LocationStatus.success, locations: locations);
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: LocationStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
  }

  Future<void> _onLocationDelete(
    LocationDelete event,
    Emitter<LocationState> emit,
  ) async {
    List<Location> locations = List.from(state.locations);
    ApiResult<Location> compResult = await repos.deleteLocation(event.location);
    return emit(compResult.when(
        success: (data) {
          int index = locations.indexWhere(
              (element) => element.locationId == event.location.locationId);
          locations.removeAt(index);
          return state.copyWith(
              status: LocationStatus.success, locations: locations);
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: LocationStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }
}

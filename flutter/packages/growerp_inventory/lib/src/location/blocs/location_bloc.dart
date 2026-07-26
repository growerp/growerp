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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:equatable/equatable.dart';

part 'location_event.dart';
part 'location_state.dart';

const _locationSearchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> locationDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

EventTransformer<LocationSearchChanged> locationSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_locationSearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc(this.restClient) : super(const LocationState()) {
    on<LocationFetch>(
      _onLocationFetch,
      transformer: locationDroppable(const Duration(milliseconds: 100)),
    );
    on<LocationUpdate>(_onLocationUpdate);
    on<LocationDelete>(_onLocationDelete);
    on<LocationSearchChanged>(
      _onLocationSearchChanged,
      transformer: locationSearchDebounce(),
    );
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
        start: start,
        searchString: event.searchString,
        limit: event.limit,
      );

      return emit(
        state.copyWith(
          status: LocationStatus.success,
          locations: start == 0
              ? compResult.locations
              : (List.of(state.locations)..addAll(compResult.locations)),
          hasReachedMax: compResult.locations.length < event.limit
              ? true
              : false,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LocationStatus.failure,
          locations: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onLocationSearchChanged(
    LocationSearchChanged event,
    Emitter<LocationState> emit,
  ) async {
    return _onLocationFetch(
      LocationFetch(
        searchString: event.searchString,
        refresh: true,
        limit: event.limit,
      ),
      emit,
    );
  }

  Future<void> _onLocationUpdate(
    LocationUpdate event,
    Emitter<LocationState> emit,
  ) async {
    try {
      List<Location> locations = List.from(state.locations);
      if (event.location.locationId != null) {
        Location compResult = await restClient.updateLocation(
          location: event.location,
        );
        int index = locations.indexWhere(
          (element) => element.locationId == event.location.locationId,
        );
        locations[index] = compResult;
        return emit(
          state.copyWith(status: LocationStatus.success, locations: locations),
        );
      } else {
        // add
        Location compResult = await restClient.createLocation(
          location: event.location,
        );
        locations.insert(0, compResult);
        return emit(
          state.copyWith(status: LocationStatus.success, locations: locations),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LocationStatus.failure,
          locations: [],
          message: await getDioError(e),
        ),
      );
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
        (element) => element.locationId == event.location.locationId,
      );
      locations.removeAt(index);
      return emit(
        state.copyWith(status: LocationStatus.success, locations: locations),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: LocationStatus.failure,
          locations: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}

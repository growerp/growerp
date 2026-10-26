import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// Fetch is throttled 100ms, SearchChanged debounced 300ms.
const fetchWait = Duration(milliseconds: 150);
const searchWait = Duration(milliseconds: 400);

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('LocationBloc', () {
    final shelfA = Location(locationId: 'L1', locationName: 'Shelf A');
    final shelfB = Location(locationId: 'L2', locationName: 'Shelf B');

    TypeMatcher<LocationState> locationState(
      LocationStatus status, {
      List<Location>? locations,
      String? message,
    }) {
      var m = isA<LocationState>().having((s) => s.status, 'status', status);
      if (locations != null) {
        m = m.having((s) => s.locations, 'locations', locations);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    LocationBloc build() => LocationBloc(restClient);

    blocTest<LocationBloc, LocationState>(
      'LocationFetch_initial_loadsFirstPage',
      setUp: () => when(
        () => restClient.getLocation(start: 0, searchString: '', limit: 20),
      ).thenAnswer((_) async => Locations(locations: [shelfA, shelfB])),
      build: build,
      act: (bloc) => bloc.add(const LocationFetch()),
      wait: fetchWait,
      expect: () => [
        locationState(LocationStatus.loading),
        locationState(LocationStatus.success, locations: [shelfA, shelfB]),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'LocationFetch_nextPage_appends',
      setUp: () => when(
        () => restClient.getLocation(start: 1, searchString: '', limit: 20),
      ).thenAnswer((_) async => Locations(locations: [shelfB])),
      build: build,
      seed: () =>
          LocationState(status: LocationStatus.success, locations: [shelfA]),
      act: (bloc) => bloc.add(const LocationFetch()),
      wait: fetchWait,
      expect: () => [
        locationState(LocationStatus.loading),
        locationState(LocationStatus.success, locations: [shelfA, shelfB]),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'LocationSearchChanged_threeChars_searchesFromStart',
      setUp: () => when(
        () => restClient.getLocation(start: 0, searchString: 'She', limit: 20),
      ).thenAnswer((_) async => Locations(locations: [shelfA])),
      build: build,
      act: (bloc) => bloc.add(const LocationSearchChanged(searchString: 'She')),
      wait: searchWait,
      expect: () => [
        locationState(LocationStatus.loading),
        locationState(LocationStatus.success, locations: [shelfA]),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'LocationFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getLocation(start: 0, searchString: '', limit: 20),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const LocationFetch()),
      wait: fetchWait,
      expect: () => [
        locationState(LocationStatus.loading),
        locationState(
          LocationStatus.failure,
          locations: [],
          message: 'No access',
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'LocationUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createLocation(
          location: Location(locationName: 'Shelf B'),
        ),
      ).thenAnswer((_) async => shelfB),
      build: build,
      seed: () => LocationState(locations: [shelfA]),
      act: (bloc) =>
          bloc.add(LocationUpdate(Location(locationName: 'Shelf B'))),
      expect: () => [
        locationState(LocationStatus.success, locations: [shelfB, shelfA]),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'LocationUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateLocation(
          location: shelfA.copyWith(locationName: 'Shelf A1'),
        ),
      ).thenAnswer((_) async => shelfA.copyWith(locationName: 'Shelf A1')),
      build: build,
      seed: () => LocationState(locations: [shelfA, shelfB]),
      act: (bloc) =>
          bloc.add(LocationUpdate(shelfA.copyWith(locationName: 'Shelf A1'))),
      expect: () => [
        locationState(
          LocationStatus.success,
          locations: [
            shelfA.copyWith(locationName: 'Shelf A1'),
            shelfB,
          ],
        ),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'LocationDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteLocation(location: shelfA),
      ).thenAnswer((_) async => shelfA),
      build: build,
      seed: () => LocationState(locations: [shelfA, shelfB]),
      act: (bloc) => bloc.add(LocationDelete(shelfA)),
      expect: () => [
        locationState(LocationStatus.success, locations: [shelfB]),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'LocationDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteLocation(location: shelfA),
      ).thenThrow(dioError('Has stock')),
      build: build,
      seed: () => LocationState(locations: [shelfA]),
      act: (bloc) => bloc.add(LocationDelete(shelfA)),
      expect: () => [
        locationState(LocationStatus.failure, message: 'Has stock'),
      ],
    );
  });

  group('AssetBloc', () {
    final room1 = Asset(assetId: 'A1', assetName: 'Room 1');
    final room2 = Asset(assetId: 'A2', assetName: 'Room 2');

    TypeMatcher<AssetState> assetState(
      AssetStatus status, {
      List<Asset>? assets,
      String? message,
    }) {
      var m = isA<AssetState>().having((s) => s.status, 'status', status);
      if (assets != null) m = m.having((s) => s.assets, 'assets', assets);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    AssetBloc build() => AssetBloc(restClient, 'AppHotel');

    blocTest<AssetBloc, AssetState>(
      'AssetFetch_refreshForClass_clearsThenLoads',
      setUp: () => when(
        () => restClient.getAsset(
          searchString: '',
          assetClassId: 'Room',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer((_) async => Assets(assets: [room1, room2])),
      build: build,
      act: (bloc) =>
          bloc.add(const AssetFetch(refresh: true, assetClassId: 'Room')),
      wait: fetchWait,
      expect: () => [
        assetState(AssetStatus.loading, assets: []),
        assetState(
          AssetStatus.success,
          assets: [room1, room2],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<AssetBloc, AssetState>(
      'AssetFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getAsset(
          searchString: '',
          assetClassId: '',
          start: 0,
          limit: 20,
        ),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const AssetFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        assetState(AssetStatus.loading),
        assetState(AssetStatus.failure, assets: [], message: 'No access'),
      ],
    );

    blocTest<AssetBloc, AssetState>(
      'AssetSearchChanged_threeChars_searchesFromStart',
      setUp: () => when(
        () => restClient.getAsset(
          searchString: 'Roo',
          assetClassId: '',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer((_) async => Assets(assets: [room1])),
      build: build,
      act: (bloc) => bloc.add(const AssetSearchChanged(searchString: 'Roo')),
      wait: searchWait,
      expect: () => [
        assetState(AssetStatus.loading, assets: []),
        assetState(AssetStatus.success, assets: [room1]),
      ],
    );

    blocTest<AssetBloc, AssetState>(
      'AssetUpdate_new_createsWithStoreAndInsertsFirst',
      setUp: () => when(
        () => restClient.createAsset(
          asset: Asset(assetName: 'Room 2'),
          applicationId: 'AppHotel',
        ),
      ).thenAnswer((_) async => room2),
      build: build,
      seed: () => AssetState(assets: [room1]),
      act: (bloc) => bloc.add(AssetUpdate(Asset(assetName: 'Room 2'))),
      expect: () => [
        assetState(AssetStatus.loading),
        assetState(
          AssetStatus.success,
          assets: [room2, room1],
          message: 'assetAddSuccess:Room 2',
        ),
      ],
    );

    blocTest<AssetBloc, AssetState>(
      'AssetUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateAsset(
          asset: room1.copyWith(assetName: 'Suite 1'),
          applicationId: 'AppHotel',
        ),
      ).thenAnswer((_) async => room1.copyWith(assetName: 'Suite 1')),
      build: build,
      seed: () => AssetState(assets: [room1, room2]),
      act: (bloc) =>
          bloc.add(AssetUpdate(room1.copyWith(assetName: 'Suite 1'))),
      expect: () => [
        assetState(AssetStatus.loading),
        assetState(
          AssetStatus.success,
          assets: [
            room1.copyWith(assetName: 'Suite 1'),
            room2,
          ],
          message: 'assetUpdateSuccess:Suite 1',
        ),
      ],
    );

    // https://github.com/growerp/growerp/issues/45
    group('AssetFetch paging', () {
      blocTest<AssetBloc, AssetState>(
        'AssetFetch_nextPage_requestsFromCurrentLength',
        setUp: () => when(
          () => restClient.getAsset(
            searchString: '',
            assetClassId: '',
            start: 1,
            limit: 20,
          ),
        ).thenAnswer((_) async => Assets(assets: [room2])),
        build: build,
        seed: () => AssetState(status: AssetStatus.success, assets: [room1]),
        act: (bloc) => bloc.add(const AssetFetch()),
        wait: fetchWait,
        verify: (bloc) => expect(bloc.state.assets, [room1, room2]),
      );
    });
  });
}

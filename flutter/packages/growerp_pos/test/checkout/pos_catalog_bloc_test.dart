import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final beer = PosCatalogItem(
    productId: 'P1',
    productName: 'Beer',
    price: Decimal.fromInt(5),
  );

  setUp(() => restClient = MockRestClient());

  group('PosCatalogFetch', () {
    blocTest<PosCatalogBloc, PosCatalogState>(
      'PosCatalogFetch_initial_loadsItemsAndTaxSetting',
      setUp: () => when(() => restClient.getPosCatalog()).thenAnswer(
        (_) async => PosCatalog(
          items: [beer],
          pricesIncludeTax: true,
          currencyId: 'EUR',
        ),
      ),
      build: () => PosCatalogBloc(restClient),
      act: (bloc) => bloc.add(const PosCatalogFetch()),
      expect: () => [
        isA<PosCatalogState>().having(
          (s) => s.status,
          'status',
          PosCatalogStatus.loading,
        ),
        isA<PosCatalogState>()
            .having((s) => s.status, 'status', PosCatalogStatus.success)
            .having((s) => s.items, 'items', [beer])
            .having((s) => s.pricesIncludeTax, 'inclusive', true)
            .having((s) => s.currencyId, 'currency', 'EUR'),
      ],
    );

    blocTest<PosCatalogBloc, PosCatalogState>(
      'PosCatalogFetch_alreadyLoaded_doesNotFetchAgain',
      build: () => PosCatalogBloc(restClient),
      seed: () => const PosCatalogState(status: PosCatalogStatus.success),
      act: (bloc) => bloc.add(const PosCatalogFetch()),
      expect: () => <PosCatalogState>[],
      verify: (_) => verifyNever(() => restClient.getPosCatalog()),
    );

    blocTest<PosCatalogBloc, PosCatalogState>(
      'PosCatalogFetch_restError_failure',
      setUp: () => when(
        () => restClient.getPosCatalog(),
      ).thenThrow(dioError('no connection')),
      build: () => PosCatalogBloc(restClient),
      act: (bloc) => bloc.add(const PosCatalogFetch()),
      expect: () => [
        isA<PosCatalogState>(),
        isA<PosCatalogState>().having(
          (s) => s.status,
          'status',
          PosCatalogStatus.failure,
        ),
      ],
    );
  });

  group('PosBarcodeScan', () {
    blocTest<PosCatalogBloc, PosCatalogState>(
      'PosBarcodeScan_known_givesProduct',
      setUp: () => when(
        () => restClient.getPosProductByBarcode(barcode: '871'),
      ).thenAnswer((_) async => beer),
      build: () => PosCatalogBloc(restClient),
      act: (bloc) => bloc.add(const PosBarcodeScan('871')),
      expect: () => [
        isA<PosCatalogState>()
            .having((s) => s.status, 'status', PosCatalogStatus.scanned)
            .having((s) => s.scanned, 'scanned', beer),
      ],
    );

    blocTest<PosCatalogBloc, PosCatalogState>(
      'PosBarcodeScan_unknown_failure',
      setUp: () => when(
        () => restClient.getPosProductByBarcode(barcode: '000'),
      ).thenThrow(dioError('not found')),
      build: () => PosCatalogBloc(restClient),
      act: (bloc) => bloc.add(const PosBarcodeScan('000')),
      expect: () => [
        isA<PosCatalogState>().having(
          (s) => s.status,
          'status',
          PosCatalogStatus.failure,
        ),
      ],
    );
  });
}

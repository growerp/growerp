import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<TaxRateState> taxState(
  TaxRateStatus status, {
  List<TaxRate>? rates,
  bool? pricesIncludeTax,
  String? message,
}) {
  var m = isA<TaxRateState>().having((s) => s.status, 'status', status);
  if (rates != null) m = m.having((s) => s.taxRates, 'taxRates', rates);
  if (pricesIncludeTax != null) {
    m = m.having(
      (s) => s.pricesIncludeTax,
      'pricesIncludeTax',
      pricesIncludeTax,
    );
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final vat = TaxRate(
    taxRateId: 'R1',
    taxName: 'VAT',
    taxPercentage: Decimal.fromInt(21),
  );
  final changed = vat.copyWith(taxPercentage: Decimal.fromInt(9));
  final draft = TaxRate(taxName: 'VAT', taxPercentage: Decimal.fromInt(21));
  final dioError = DioException(
    requestOptions: RequestOptions(path: 'rest'),
    type: DioExceptionType.connectionError,
  );

  setUpAll(() => registerFallbackValue(TaxRate()));
  setUp(() => restClient = MockRestClient());

  group('TaxRateFetch', () {
    blocTest<TaxRateBloc, TaxRateState>(
      'TaxRateFetch_loadsRatesAndSetting',
      setUp: () => when(() => restClient.getTaxRates()).thenAnswer(
        (_) async => TaxRates(taxRates: [vat], pricesIncludeTax: true),
      ),
      build: () => TaxRateBloc(restClient),
      act: (bloc) => bloc.add(const TaxRateFetch()),
      expect: () => [
        taxState(TaxRateStatus.loading),
        taxState(TaxRateStatus.success, rates: [vat], pricesIncludeTax: true),
      ],
    );

    blocTest<TaxRateBloc, TaxRateState>(
      'TaxRateFetch_restError_failure',
      setUp: () => when(() => restClient.getTaxRates()).thenThrow(dioError),
      build: () => TaxRateBloc(restClient),
      act: (bloc) => bloc.add(const TaxRateFetch()),
      expect: () => [
        taxState(TaxRateStatus.loading),
        taxState(TaxRateStatus.failure),
      ],
    );
  });

  group('TaxRateUpdate', () {
    blocTest<TaxRateBloc, TaxRateState>(
      'TaxRateUpdate_noId_createsAndAddsFirst',
      setUp: () => when(
        () => restClient.createTaxRate(taxRate: draft),
      ).thenAnswer((_) async => vat),
      build: () => TaxRateBloc(restClient),
      act: (bloc) => bloc.add(TaxRateUpdate(draft)),
      expect: () => [
        taxState(TaxRateStatus.loading),
        taxState(
          TaxRateStatus.success,
          rates: [vat],
          message: 'taxRateAddSuccess',
        ),
      ],
    );

    blocTest<TaxRateBloc, TaxRateState>(
      'TaxRateUpdate_withId_replacesInList',
      setUp: () => when(
        () => restClient.updateTaxRate(taxRate: changed),
      ).thenAnswer((_) async => changed),
      build: () => TaxRateBloc(restClient),
      seed: () => TaxRateState(status: TaxRateStatus.success, taxRates: [vat]),
      act: (bloc) => bloc.add(TaxRateUpdate(changed)),
      expect: () => [
        taxState(TaxRateStatus.loading),
        taxState(
          TaxRateStatus.success,
          rates: [changed],
          message: 'taxRateUpdateSuccess',
        ),
      ],
    );

    blocTest<TaxRateBloc, TaxRateState>(
      'TaxRateUpdate_restError_failureKeepsList',
      setUp: () => when(
        () => restClient.updateTaxRate(taxRate: any(named: 'taxRate')),
      ).thenThrow(dioError),
      build: () => TaxRateBloc(restClient),
      seed: () => TaxRateState(status: TaxRateStatus.success, taxRates: [vat]),
      act: (bloc) => bloc.add(TaxRateUpdate(changed)),
      expect: () => [
        taxState(TaxRateStatus.loading),
        taxState(TaxRateStatus.failure, rates: [vat]),
      ],
    );
  });

  group('TaxRateDelete', () {
    blocTest<TaxRateBloc, TaxRateState>(
      'TaxRateDelete_removesFromList',
      setUp: () => when(
        () => restClient.deleteTaxRate(taxRateId: 'R1'),
      ).thenAnswer((_) async {}),
      build: () => TaxRateBloc(restClient),
      seed: () => TaxRateState(status: TaxRateStatus.success, taxRates: [vat]),
      act: (bloc) => bloc.add(TaxRateDelete(vat)),
      expect: () => [
        taxState(TaxRateStatus.loading),
        taxState(
          TaxRateStatus.success,
          rates: const [],
          message: 'taxRateDeleteSuccess',
        ),
      ],
    );
  });

  group('TaxSettingsUpdate', () {
    blocTest<TaxRateBloc, TaxRateState>(
      'TaxSettingsUpdate_storesSetting',
      setUp: () => when(
        () => restClient.updateTaxSettings(pricesIncludeTax: true),
      ).thenAnswer((_) async {}),
      build: () => TaxRateBloc(restClient),
      act: (bloc) => bloc.add(const TaxSettingsUpdate(pricesIncludeTax: true)),
      expect: () => [taxState(TaxRateStatus.success, pricesIncludeTax: true)],
    );
  });
}

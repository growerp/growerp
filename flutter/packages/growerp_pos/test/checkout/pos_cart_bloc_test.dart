import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final beer = PosCatalogItem(productId: 'P1', price: Decimal.fromInt(5));
  final wine = PosCatalogItem(productId: 'P2', price: Decimal.fromInt(7));

  setUpAll(() => registerFallbackValue(<PosLine>[]));
  setUp(() {
    restClient = MockRestClient();
    when(() => restClient.getPosQuote(lines: any(named: 'lines'))).thenAnswer(
      (_) async =>
          PosQuote(taxTotal: Decimal.one, grandTotal: Decimal.fromInt(11)),
    );
  });

  blocTest<PosCartBloc, PosCartState>(
    'PosCartAdd_new_addsLineWithBackendTotals',
    build: () => PosCartBloc(restClient),
    act: (bloc) => bloc.add(PosCartAdd(beer)),
    expect: () => [
      isA<PosCartState>().having(
        (s) => s.status,
        'status',
        PosCartStatus.loading,
      ),
      isA<PosCartState>()
          .having((s) => s.status, 'status', PosCartStatus.success)
          .having((s) => s.lines.length, 'lines', 1)
          .having((s) => s.grandTotal, 'total', Decimal.fromInt(11))
          .having((s) => s.taxTotal, 'tax', Decimal.one),
    ],
  );

  blocTest<PosCartBloc, PosCartState>(
    'PosCartAdd_sameProductTwice_raisesQuantity',
    build: () => PosCartBloc(restClient),
    act: (bloc) => bloc
      ..add(PosCartAdd(beer))
      ..add(PosCartAdd(beer)),
    verify: (bloc) {
      expect(bloc.state.lines.length, 1);
      expect(bloc.state.lines[0].quantity, Decimal.fromInt(2));
    },
  );

  blocTest<PosCartBloc, PosCartState>(
    'PosCartQuantity_zero_removesLine',
    build: () => PosCartBloc(restClient),
    seed: () => PosCartState(
      lines: [PosCartLine(beer, Decimal.one), PosCartLine(wine, Decimal.one)],
    ),
    act: (bloc) => bloc.add(PosCartQuantity('P1', Decimal.zero)),
    verify: (bloc) {
      expect(bloc.state.lines.map((l) => l.item.productId), ['P2']);
    },
  );

  blocTest<PosCartBloc, PosCartState>(
    'PosCartQuantity_lastLineToZero_emptiesWithoutQuote',
    build: () => PosCartBloc(restClient),
    seed: () => PosCartState(lines: [PosCartLine(beer, Decimal.one)]),
    act: (bloc) => bloc.add(PosCartQuantity('P1', Decimal.zero)),
    expect: () => [const PosCartState(status: PosCartStatus.success)],
    verify: (_) =>
        verifyNever(() => restClient.getPosQuote(lines: any(named: 'lines'))),
  );

  blocTest<PosCartBloc, PosCartState>(
    'PosCartClear_emptiesTheSale',
    build: () => PosCartBloc(restClient),
    seed: () => PosCartState(
      lines: [PosCartLine(beer, Decimal.one)],
      grandTotal: Decimal.fromInt(5),
    ),
    act: (bloc) => bloc.add(const PosCartClear()),
    expect: () => [const PosCartState(status: PosCartStatus.success)],
  );

  blocTest<PosCartBloc, PosCartState>(
    'PosCartAdd_quoteFails_failureKeepsLine',
    setUp: () => when(
      () => restClient.getPosQuote(lines: any(named: 'lines')),
    ).thenThrow(dioError('no connection')),
    build: () => PosCartBloc(restClient),
    act: (bloc) => bloc.add(PosCartAdd(beer)),
    expect: () => [
      isA<PosCartState>(),
      isA<PosCartState>()
          .having((s) => s.status, 'status', PosCartStatus.failure)
          .having((s) => s.lines.length, 'lines', 1),
    ],
  );
}

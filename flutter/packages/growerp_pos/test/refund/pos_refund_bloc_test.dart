import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final sale = PosSale(clientSaleId: 'S1');
  final lines = [PosRefundLine(orderItemSeqId: '01', quantity: Decimal.one)];
  final refund = PosRefund(amount: Decimal.fromInt(5), method: 'PiCash');

  void stubRefund(Future<PosRefund> Function() answer) => when(
    () => restClient.createPosRefund(
      clientRefundId: any(named: 'clientRefundId'),
      clientSaleId: any(named: 'clientSaleId'),
      lines: any(named: 'lines'),
      restock: any(named: 'restock'),
    ),
  ).thenAnswer((_) => answer());

  setUpAll(() => registerFallbackValue(<PosRefundLine>[]));
  setUp(() => restClient = MockRestClient());

  blocTest<PosRefundBloc, PosRefundState>(
    'PosRefundLookup_found_givesTheSale',
    setUp: () => when(
      () => restClient.getPosSaleLookup(search: '100'),
    ).thenAnswer((_) async => sale),
    build: () => PosRefundBloc(restClient),
    act: (bloc) => bloc.add(const PosRefundLookup('100')),
    expect: () => [
      isA<PosRefundState>().having(
        (s) => s.status,
        'status',
        PosRefundStatus.loading,
      ),
      isA<PosRefundState>()
          .having((s) => s.status, 'status', PosRefundStatus.found)
          .having((s) => s.sale, 'sale', sale),
    ],
  );

  blocTest<PosRefundBloc, PosRefundState>(
    'PosRefundLookup_unknown_failure',
    setUp: () => when(
      () => restClient.getPosSaleLookup(search: 'x'),
    ).thenThrow(dioError('no sale')),
    build: () => PosRefundBloc(restClient),
    act: (bloc) => bloc.add(const PosRefundLookup('x')),
    expect: () => [
      isA<PosRefundState>(),
      isA<PosRefundState>().having(
        (s) => s.status,
        'status',
        PosRefundStatus.failure,
      ),
    ],
  );

  blocTest<PosRefundBloc, PosRefundState>(
    'PosRefundSubmit_success_givesTheRefund',
    setUp: () => stubRefund(() async => refund),
    build: () => PosRefundBloc(restClient),
    seed: () => PosRefundState(status: PosRefundStatus.found, sale: sale),
    act: (bloc) => bloc.add(PosRefundSubmit(lines: lines, restock: true)),
    expect: () => [
      isA<PosRefundState>(),
      isA<PosRefundState>()
          .having((s) => s.status, 'status', PosRefundStatus.success)
          .having((s) => s.refund, 'refund', refund),
    ],
  );

  test('PosRefundSubmit_retryAfterFailure_sendsTheSameId', () async {
    stubRefund(() async => throw dioError('connection lost'));
    final bloc = PosRefundBloc(restClient);
    bloc.emit(PosRefundState(status: PosRefundStatus.found, sale: sale));

    bloc.add(PosRefundSubmit(lines: lines, restock: true));
    await bloc.stream.firstWhere((s) => s.status == PosRefundStatus.failure);
    bloc.add(PosRefundSubmit(lines: lines, restock: true));
    await bloc.stream
        .skip(1)
        .firstWhere((s) => s.status == PosRefundStatus.failure);

    final ids = verify(
      () => restClient.createPosRefund(
        clientRefundId: captureAny(named: 'clientRefundId'),
        clientSaleId: any(named: 'clientSaleId'),
        lines: any(named: 'lines'),
        restock: any(named: 'restock'),
      ),
    ).captured;
    expect(ids.length, 2);
    expect(ids[0], ids[1]);
    await bloc.close();
  });
}

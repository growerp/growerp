import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final lines = [PosLine(productId: 'P1', quantity: Decimal.one)];
  final tenders = [PosTender(method: 'PiCash', amount: Decimal.fromInt(5))];
  final sale = PosSale(orderId: 'O1', grandTotal: Decimal.fromInt(5));

  void stubSale(Future<PosSale> Function() answer) => when(
    () => restClient.createPosSale(
      clientSaleId: any(named: 'clientSaleId'),
      terminalName: any(named: 'terminalName'),
      lines: any(named: 'lines'),
      tenders: any(named: 'tenders'),
    ),
  ).thenAnswer((_) => answer());

  List<String> sentIds() => verify(
    () => restClient.createPosSale(
      clientSaleId: captureAny(named: 'clientSaleId'),
      terminalName: any(named: 'terminalName'),
      lines: any(named: 'lines'),
      tenders: any(named: 'tenders'),
    ),
  ).captured.cast<String>();

  setUpAll(() {
    registerFallbackValue(<PosLine>[]);
    registerFallbackValue(<PosTender>[]);
  });
  setUp(() => restClient = MockRestClient());

  blocTest<PosSaleBloc, PosSaleState>(
    'PosSaleSubmit_success_givesTheSale',
    setUp: () => stubSale(() async => sale),
    build: () => PosSaleBloc(restClient),
    act: (bloc) => bloc.add(PosSaleSubmit(lines: lines, tenders: tenders)),
    expect: () => [
      isA<PosSaleState>().having(
        (s) => s.status,
        'status',
        PosSaleStatus.loading,
      ),
      isA<PosSaleState>()
          .having((s) => s.status, 'status', PosSaleStatus.success)
          .having((s) => s.sale, 'sale', sale),
    ],
  );

  test('PosSaleSubmit_retryAfterFailure_sendsTheSameId', () async {
    stubSale(() async => throw dioError('connection lost'));
    final bloc = PosSaleBloc(restClient);

    bloc.add(PosSaleSubmit(lines: lines, tenders: tenders));
    await bloc.stream.firstWhere((s) => s.status == PosSaleStatus.failure);
    bloc.add(PosSaleSubmit(lines: lines, tenders: tenders));
    await bloc.stream
        .skip(1)
        .firstWhere((s) => s.status == PosSaleStatus.failure);

    final ids = sentIds();
    expect(ids.length, 2);
    expect(ids[0], ids[1]);
    await bloc.close();
  });

  test('PosSaleReset_nextSale_sendsANewId', () async {
    stubSale(() async => sale);
    final bloc = PosSaleBloc(restClient);

    bloc.add(PosSaleSubmit(lines: lines, tenders: tenders));
    await bloc.stream.firstWhere((s) => s.status == PosSaleStatus.success);
    bloc.add(const PosSaleReset());
    await bloc.stream.firstWhere((s) => s.status == PosSaleStatus.initial);
    bloc.add(PosSaleSubmit(lines: lines, tenders: tenders));
    await bloc.stream.firstWhere((s) => s.status == PosSaleStatus.success);

    final ids = sentIds();
    expect(ids.length, 2);
    expect(ids[0], isNot(ids[1]));
    await bloc.close();
  });
}

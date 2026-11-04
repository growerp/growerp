import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final ticket = PosTicket(ticketId: 'K1');
  PosTabLine line(String status) =>
      PosTabLine(orderId: 'O1', orderItemSeqId: '01', kitchenStatus: status);

  setUp(() {
    restClient = MockRestClient();
    when(
      () => restClient.getPosKitchen(),
    ).thenAnswer((_) async => PosTickets(tickets: [ticket]));
  });

  void stubUpdate(String status) => when(
    () => restClient.updatePosKitchenLine(
      orderId: 'O1',
      orderItemSeqId: '01',
      kitchenStatus: status,
    ),
  ).thenAnswer((_) async {});

  blocTest<PosKitchenBloc, PosKitchenState>(
    'PosKitchenFetch_givesTheTickets',
    build: () => PosKitchenBloc(restClient),
    act: (bloc) => bloc.add(const PosKitchenFetch()),
    expect: () => [
      isA<PosKitchenState>().having((s) => s.tickets, 'tickets', [ticket]),
    ],
  );

  blocTest<PosKitchenBloc, PosKitchenState>(
    'PosKitchenBump_sent_becomesReady',
    setUp: () => stubUpdate('Ready'),
    build: () => PosKitchenBloc(restClient),
    act: (bloc) => bloc.add(PosKitchenBump(line('Sent'))),
    verify: (_) => verify(
      () => restClient.updatePosKitchenLine(
        orderId: 'O1',
        orderItemSeqId: '01',
        kitchenStatus: 'Ready',
      ),
    ).called(1),
  );

  blocTest<PosKitchenBloc, PosKitchenState>(
    'PosKitchenBump_ready_becomesServed',
    setUp: () => stubUpdate('Served'),
    build: () => PosKitchenBloc(restClient),
    act: (bloc) => bloc.add(PosKitchenBump(line('Ready'))),
    verify: (_) => verify(
      () => restClient.updatePosKitchenLine(
        orderId: 'O1',
        orderItemSeqId: '01',
        kitchenStatus: 'Served',
      ),
    ).called(1),
  );

  blocTest<PosKitchenBloc, PosKitchenState>(
    'PosKitchenFetch_restError_failure',
    setUp: () => when(
      () => restClient.getPosKitchen(),
    ).thenThrow(dioError('no connection')),
    build: () => PosKitchenBloc(restClient),
    act: (bloc) => bloc.add(const PosKitchenFetch()),
    expect: () => [
      isA<PosKitchenState>().having(
        (s) => s.status,
        'status',
        PosKitchenStatus.failure,
      ),
    ],
  );
}

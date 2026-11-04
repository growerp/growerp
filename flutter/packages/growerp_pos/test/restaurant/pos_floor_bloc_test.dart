import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final table = PosTable(assetId: 'A1', tableName: 'T1');

  TypeMatcher<PosFloorState> status(PosFloorStatus status) =>
      isA<PosFloorState>().having((s) => s.status, 'status', status);

  setUpAll(() => registerFallbackValue(PosTable()));
  setUp(() {
    restClient = MockRestClient();
    when(
      () => restClient.getPosFloorPlan(),
    ).thenAnswer((_) async => PosTables(tables: [table]));
  });

  blocTest<PosFloorBloc, PosFloorState>(
    'PosFloorFetch_givesTheTables',
    build: () => PosFloorBloc(restClient),
    act: (bloc) => bloc.add(const PosFloorFetch()),
    expect: () => [
      status(PosFloorStatus.success).having((s) => s.tables, 'tables', [table]),
    ],
  );

  blocTest<PosFloorBloc, PosFloorState>(
    'PosTableSave_noId_creates',
    setUp: () => when(
      () => restClient.createPosTable(table: any(named: 'table')),
    ).thenAnswer((_) async => table),
    build: () => PosFloorBloc(restClient),
    act: (bloc) => bloc.add(PosTableSave(PosTable(tableName: 'T1'))),
    expect: () => [
      status(
        PosFloorStatus.success,
      ).having((s) => s.message, 'message', 'saved'),
    ],
  );

  blocTest<PosFloorBloc, PosFloorState>(
    'PosTableSave_withId_updates',
    setUp: () => when(
      () => restClient.updatePosTable(table: table),
    ).thenAnswer((_) async {}),
    build: () => PosFloorBloc(restClient),
    act: (bloc) => bloc.add(PosTableSave(table)),
    verify: (_) => verifyNever(
      () => restClient.createPosTable(table: any(named: 'table')),
    ),
  );

  blocTest<PosFloorBloc, PosFloorState>(
    'PosTableDelete_openTab_failure',
    setUp: () => when(
      () => restClient.deletePosTable(assetId: 'A1'),
    ).thenThrow(dioError('open tab')),
    build: () => PosFloorBloc(restClient),
    act: (bloc) => bloc.add(const PosTableDelete('A1')),
    expect: () => [status(PosFloorStatus.failure)],
  );
}

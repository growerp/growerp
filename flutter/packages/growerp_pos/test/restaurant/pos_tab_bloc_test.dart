import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final tab = PosTab(tabId: 'T1', orderId: 'O1');
  final changed = PosTab(tabId: 'T1', grandTotal: Decimal.fromInt(5));

  TypeMatcher<PosTabState> status(PosTabStatus status) =>
      isA<PosTabState>().having((s) => s.status, 'status', status);

  setUpAll(() => registerFallbackValue(<PosSplitAssignment>[]));
  setUp(() => restClient = MockRestClient());

  blocTest<PosTabBloc, PosTabState>(
    'PosTabOpen_withId_readsTheTab',
    setUp: () => when(
      () => restClient.getPosTab(tabId: 'T1'),
    ).thenAnswer((_) async => tab),
    build: () => PosTabBloc(restClient),
    act: (bloc) => bloc.add(const PosTabOpen(tabId: 'T1')),
    expect: () => [
      status(PosTabStatus.loading),
      status(PosTabStatus.success).having((s) => s.tab, 'tab', tab),
    ],
  );

  blocTest<PosTabBloc, PosTabState>(
    'PosTabOpen_otherTable_doesNotShowTheOldTabWhileLoading',
    setUp: () => when(
      () => restClient.openPosTab(tableAssetId: 'A2'),
    ).thenAnswer((_) async => PosTab(tabId: 'T2')),
    build: () => PosTabBloc(restClient),
    seed: () => PosTabState(status: PosTabStatus.success, tab: tab),
    act: (bloc) => bloc.add(const PosTabOpen(tableAssetId: 'A2')),
    expect: () => [
      status(PosTabStatus.loading).having((s) => s.tab, 'tab', isNull),
      status(PosTabStatus.success),
    ],
  );

  blocTest<PosTabBloc, PosTabState>(
    'PosTabAddLine_replacesTheTabWithTheAnswer',
    setUp: () => when(
      () => restClient.addPosTabLine(
        tabId: 'T1',
        productId: 'P1',
        quantity: Decimal.one,
        modifierIds: ['M1'],
        note: 'hot',
      ),
    ).thenAnswer((_) async => changed),
    build: () => PosTabBloc(restClient),
    seed: () => PosTabState(tab: tab),
    act: (bloc) =>
        bloc.add(const PosTabAddLine('P1', modifierIds: ['M1'], note: 'hot')),
    expect: () => [
      status(PosTabStatus.loading),
      status(PosTabStatus.success).having((s) => s.tab, 'tab', changed),
    ],
  );

  blocTest<PosTabBloc, PosTabState>(
    'PosTabSend_restError_failureKeepsTheTab',
    setUp: () => when(
      () => restClient.sendPosTab(tabId: 'T1'),
    ).thenThrow(dioError('tab is closed')),
    build: () => PosTabBloc(restClient),
    seed: () => PosTabState(tab: tab),
    act: (bloc) => bloc.add(const PosTabSend()),
    expect: () => [
      status(PosTabStatus.loading),
      status(PosTabStatus.failure).having((s) => s.tab, 'tab', tab),
    ],
  );

  blocTest<PosTabBloc, PosTabState>(
    'PosTabVoidLine_givesTheReason',
    setUp: () => when(
      () => restClient.voidPosTabLine(
        tabId: 'T1',
        orderItemSeqId: '01',
        reason: 'spilled',
      ),
    ).thenAnswer((_) async => changed),
    build: () => PosTabBloc(restClient),
    seed: () => PosTabState(tab: tab),
    act: (bloc) => bloc.add(const PosTabVoidLine('01', reason: 'spilled')),
    expect: () => [
      status(PosTabStatus.loading),
      status(PosTabStatus.success).having((s) => s.tab, 'tab', changed),
    ],
  );

  blocTest<PosTabBloc, PosTabState>(
    'PosTabSplit_ownStatusWithTheShares',
    setUp: () => when(
      () => restClient.splitPosTab(tabId: 'T1', ways: 2),
    ).thenAnswer((_) async => PosShares(shares: [PosShare(splitNo: 1)])),
    build: () => PosTabBloc(restClient),
    seed: () => PosTabState(tab: tab),
    act: (bloc) => bloc.add(const PosTabSplit(ways: 2)),
    expect: () => [
      status(PosTabStatus.loading),
      status(PosTabStatus.split).having((s) => s.shares.length, 'shares', 1),
    ],
  );

  blocTest<PosTabBloc, PosTabState>(
    'PosTabCancel_closesAndForgetsTheTab',
    setUp: () => when(
      () => restClient.cancelPosTab(tabId: 'T1'),
    ).thenAnswer((_) async {}),
    build: () => PosTabBloc(restClient),
    seed: () => PosTabState(tab: tab),
    act: (bloc) => bloc.add(const PosTabCancel()),
    expect: () => [
      status(PosTabStatus.loading),
      status(PosTabStatus.closed).having((s) => s.tab, 'tab', isNull),
    ],
  );
}

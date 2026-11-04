import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;
  final shift = PosShift(shiftId: 'S1', terminalName: 'Till 1');
  final report = PosZReport(shiftId: 'S1', status: 'Closed');
  final float = Decimal.fromInt(100);

  TypeMatcher<PosShiftState> status(PosShiftStatus status) =>
      isA<PosShiftState>().having((s) => s.status, 'status', status);

  setUp(() => restClient = MockRestClient());

  blocTest<PosShiftBloc, PosShiftState>(
    'PosShiftFetch_openTill_givesTheShift',
    setUp: () => when(
      () => restClient.getPosShift(terminalName: 'Till 1'),
    ).thenAnswer((_) async => shift),
    build: () => PosShiftBloc(restClient),
    act: (bloc) => bloc.add(const PosShiftFetch('Till 1')),
    expect: () => [
      status(PosShiftStatus.loading),
      status(PosShiftStatus.success).having((s) => s.shift, 'shift', shift),
    ],
  );

  blocTest<PosShiftBloc, PosShiftState>(
    'PosShiftFetch_closedTill_noShift',
    setUp: () => when(
      () => restClient.getPosShift(terminalName: 'Till 1'),
    ).thenAnswer((_) async => PosShift()),
    build: () => PosShiftBloc(restClient),
    seed: () => PosShiftState(shift: shift),
    act: (bloc) => bloc.add(const PosShiftFetch('Till 1')),
    expect: () => [
      status(PosShiftStatus.loading),
      status(PosShiftStatus.success).having((s) => s.shift, 'shift', isNull),
    ],
  );

  blocTest<PosShiftBloc, PosShiftState>(
    'PosShiftOpen_success_givesTheShift',
    setUp: () => when(
      () =>
          restClient.openPosShift(terminalName: 'Till 1', openingFloat: float),
    ).thenAnswer((_) async => shift),
    build: () => PosShiftBloc(restClient),
    act: (bloc) =>
        bloc.add(PosShiftOpen(terminalName: 'Till 1', openingFloat: float)),
    expect: () => [
      status(PosShiftStatus.loading),
      status(PosShiftStatus.success).having((s) => s.shift, 'shift', shift),
    ],
  );

  blocTest<PosShiftBloc, PosShiftState>(
    'PosShiftOpen_alreadyOpen_failure',
    setUp: () => when(
      () =>
          restClient.openPosShift(terminalName: 'Till 1', openingFloat: float),
    ).thenThrow(dioError('already open')),
    build: () => PosShiftBloc(restClient),
    act: (bloc) =>
        bloc.add(PosShiftOpen(terminalName: 'Till 1', openingFloat: float)),
    expect: () => [
      status(PosShiftStatus.loading),
      status(PosShiftStatus.failure),
    ],
  );

  blocTest<PosShiftBloc, PosShiftState>(
    'PosCashMovementAdd_success_keepsTheShift',
    setUp: () => when(
      () => restClient.createPosCashMovement(
        shiftId: 'S1',
        amount: Decimal.fromInt(-5),
        reason: 'Safe',
      ),
    ).thenAnswer((_) async {}),
    build: () => PosShiftBloc(restClient),
    seed: () => PosShiftState(shift: shift),
    act: (bloc) => bloc.add(
      PosCashMovementAdd(amount: Decimal.fromInt(-5), reason: 'Safe'),
    ),
    expect: () => [
      status(PosShiftStatus.loading),
      status(PosShiftStatus.success).having((s) => s.shift, 'shift', shift),
    ],
  );

  blocTest<PosShiftBloc, PosShiftState>(
    'PosShiftClose_success_clearsShiftAndGivesReport',
    setUp: () => when(
      () => restClient.closePosShift(shiftId: 'S1', countedCash: float),
    ).thenAnswer((_) async => report),
    build: () => PosShiftBloc(restClient),
    seed: () => PosShiftState(shift: shift),
    act: (bloc) => bloc.add(PosShiftClose(float)),
    expect: () => [
      status(PosShiftStatus.loading),
      status(PosShiftStatus.success)
          .having((s) => s.shift, 'shift', isNull)
          .having((s) => s.report, 'report', report),
    ],
  );

  blocTest<PosShiftBloc, PosShiftState>(
    'PosShiftClose_restError_keepsTheShift',
    setUp: () => when(
      () => restClient.closePosShift(shiftId: 'S1', countedCash: float),
    ).thenThrow(dioError('no ledger account')),
    build: () => PosShiftBloc(restClient),
    seed: () => PosShiftState(shift: shift),
    act: (bloc) => bloc.add(PosShiftClose(float)),
    expect: () => [
      status(PosShiftStatus.loading),
      status(PosShiftStatus.failure).having((s) => s.shift, 'shift', shift),
    ],
  );

  blocTest<PosShiftBloc, PosShiftState>(
    'PosShiftListFetch_refresh_replacesAndStopsAtTheEnd',
    setUp: () => when(
      () => restClient.getPosShifts(start: 0, limit: 20),
    ).thenAnswer((_) async => PosShifts(shifts: [shift])),
    build: () => PosShiftBloc(restClient),
    seed: () => PosShiftState(shifts: [PosShift(shiftId: 'old')]),
    act: (bloc) => bloc.add(const PosShiftListFetch(refresh: true)),
    expect: () => [
      status(PosShiftStatus.loading).having((s) => s.shifts, 'shifts', isEmpty),
      status(PosShiftStatus.success)
          .having((s) => s.shifts, 'shifts', [shift])
          .having((s) => s.hasReachedMax, 'max', true),
    ],
  );

  blocTest<PosShiftBloc, PosShiftState>(
    'PosZReportFetch_success_ownStatusSoNoDialogCloses',
    setUp: () => when(
      () => restClient.getPosZReport(shiftId: 'S1'),
    ).thenAnswer((_) async => report),
    build: () => PosShiftBloc(restClient),
    act: (bloc) => bloc.add(const PosZReportFetch('S1')),
    expect: () => [
      status(PosShiftStatus.loading),
      status(PosShiftStatus.reported).having((s) => s.report, 'report', report),
    ],
  );
}

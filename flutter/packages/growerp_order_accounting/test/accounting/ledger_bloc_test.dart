import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<LedgerState> ledgerState(LedgerStatus status, {String? message}) {
  var m = isA<LedgerState>().having((s) => s.status, 'status', status);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final year2026 = TimePeriod(periodId: 'TP1', periodName: 'y2026');
  final q2 = TimePeriod(periodId: 'TP2', periodName: 'q2026-2');
  final report = LedgerReport(title: 'Balance sheet');

  setUp(() => restClient = MockRestClient());

  group('LedgerFetch', () {
    blocTest<LedgerBloc, LedgerState>(
      'LedgerFetch_ledgerNoPeriod_loadsAllYearPeriodsAndLedger',
      setUp: () {
        when(
          () => restClient.getTimePeriod(year: '', periodType: 'Y'),
        ).thenAnswer((_) async => TimePeriods(timePeriods: [year2026]));
        when(() => restClient.getLedger()).thenAnswer((_) async => report);
      },
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(const LedgerFetch(ReportType.ledger)),
      expect: () => [
        ledgerState(LedgerStatus.loading),
        ledgerState(LedgerStatus.success)
            .having((s) => s.ledgerReport, 'ledgerReport', report)
            .having((s) => s.timePeriods, 'timePeriods', [year2026]),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerFetch_sheetForQuarter_loadsQuarterPeriodsOfThatYear',
      setUp: () {
        when(
          () => restClient.getTimePeriod(year: '2026', periodType: 'Q'),
        ).thenAnswer((_) async => TimePeriods(timePeriods: [q2]));
        when(
          () => restClient.getBalanceSheet(periodName: 'q2026-2'),
        ).thenAnswer((_) async => report);
      },
      build: () => LedgerBloc(restClient),
      act: (bloc) =>
          bloc.add(const LedgerFetch(ReportType.sheet, periodName: 'q2026-2')),
      expect: () => [
        ledgerState(LedgerStatus.loading),
        ledgerState(
          LedgerStatus.success,
        ).having((s) => s.ledgerReport, 'ledgerReport', report),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerFetch_summaryForMonth_usesMonthPeriods',
      setUp: () {
        when(
          () => restClient.getTimePeriod(year: '2026', periodType: 'M'),
        ).thenAnswer((_) async => TimePeriods());
        when(
          () => restClient.getBalanceSummary(periodName: 'm2026-03'),
        ).thenAnswer((_) async => report);
      },
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(
        const LedgerFetch(ReportType.summary, periodName: 'm2026-03'),
      ),
      expect: () => [
        ledgerState(LedgerStatus.loading),
        ledgerState(LedgerStatus.success),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerFetch_revenueExpense_loadsChart',
      setUp: () {
        when(
          () => restClient.getTimePeriod(year: '', periodType: 'Y'),
        ).thenAnswer((_) async => TimePeriods());
        when(
          () => restClient.getOperatingRevenueExpenseChart(periodName: 'y2026'),
        ).thenAnswer((_) async => report);
      },
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(
        const LedgerFetch(ReportType.revenueExpense, periodName: 'y2026'),
      ),
      expect: () => [
        ledgerState(LedgerStatus.loading),
        ledgerState(
          LedgerStatus.success,
        ).having((s) => s.ledgerReport, 'ledgerReport', report),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerFetch_profitLoss_setsProfitLossNotReport',
      setUp: () {
        when(
          () => restClient.getTimePeriod(year: '', periodType: 'Y'),
        ).thenAnswer((_) async => TimePeriods());
        when(
          () => restClient.getProfitLoss(periodName: 'y2026'),
        ).thenAnswer((_) async => ProfitLoss(period: year2026));
      },
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(
        const LedgerFetch(ReportType.profitLoss, periodName: 'y2026'),
      ),
      expect: () => [
        ledgerState(LedgerStatus.loading),
        ledgerState(LedgerStatus.success)
            .having((s) => s.profitLoss?.period, 'period', year2026)
            .having((s) => s.ledgerReport, 'ledgerReport', isNull),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getTimePeriod(year: '', periodType: 'Y'),
      ).thenThrow(dioError('No periods')),
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(const LedgerFetch(ReportType.ledger)),
      expect: () => [
        ledgerState(LedgerStatus.loading),
        ledgerState(LedgerStatus.failure, message: 'No periods'),
      ],
    );
  });

  group('LedgerTimePeriods', () {
    blocTest<LedgerBloc, LedgerState>(
      'LedgerTimePeriods_quarter_setsPeriods',
      setUp: () => when(
        () => restClient.getTimePeriod(periodType: 'Q'),
      ).thenAnswer((_) async => TimePeriods(timePeriods: [q2])),
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(const LedgerTimePeriods(periodType: 'Q')),
      expect: () => [
        ledgerState(
          LedgerStatus.success,
        ).having((s) => s.timePeriods, 'timePeriods', [q2]),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerTimePeriods_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getTimePeriod(periodType: 'Y'),
      ).thenThrow(dioError('No access')),
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(const LedgerTimePeriods()),
      expect: () => [ledgerState(LedgerStatus.failure, message: 'No access')],
    );
  });

  group('LedgerTimePeriodsUpdate', () {
    blocTest<LedgerBloc, LedgerState>(
      'LedgerTimePeriodsUpdate_createNext_setsPeriodsAndMessage',
      setUp: () => when(
        () =>
            restClient.updateTimePeriod(timePeriodId: 'TP1', createNext: true),
      ).thenAnswer((_) async => TimePeriods(timePeriods: [year2026, q2])),
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(
        const LedgerTimePeriodsUpdate(
          timePeriodId: 'TP1',
          createNext: true,
          timePeriodName: 'y2026',
        ),
      ),
      expect: () => [
        ledgerState(
          LedgerStatus.success,
          message: 'timePeriodUpdateSuccess:y2026',
        ).having((s) => s.timePeriods, 'timePeriods', [year2026, q2]),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerTimePeriodsUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateTimePeriod(timePeriodId: 'TP1', delete: true),
      ).thenThrow(dioError('Period has postings')),
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(
        const LedgerTimePeriodsUpdate(timePeriodId: 'TP1', delete: true),
      ),
      expect: () => [
        ledgerState(LedgerStatus.failure, message: 'Period has postings'),
      ],
    );
  });

  group('LedgerTimePeriodClose', () {
    blocTest<LedgerBloc, LedgerState>(
      'LedgerTimePeriodClose_success_setsPeriodsAndMessage',
      setUp: () => when(
        () => restClient.closeTimePeriod(timePeriodId: 'TP1'),
      ).thenAnswer((_) async => TimePeriods(timePeriods: [year2026])),
      build: () => LedgerBloc(restClient),
      act: (bloc) =>
          bloc.add(const LedgerTimePeriodClose('TP1', timePeriodName: 'y2026')),
      expect: () => [
        ledgerState(
          LedgerStatus.success,
          message: 'timePeriodCloseSuccess:y2026',
        ),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerTimePeriodClose_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.closeTimePeriod(timePeriodId: 'TP1'),
      ).thenThrow(dioError('Previous period open')),
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(const LedgerTimePeriodClose('TP1')),
      expect: () => [
        ledgerState(LedgerStatus.failure, message: 'Previous period open'),
      ],
    );
  });

  group('LedgerCalculate', () {
    blocTest<LedgerBloc, LedgerState>(
      'LedgerCalculate_started_emitsSuccess',
      setUp: () =>
          when(() => restClient.calculateLedger()).thenAnswer((_) async {}),
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(LedgerCalculate()),
      expect: () => [
        ledgerState(LedgerStatus.loading),
        ledgerState(LedgerStatus.success),
      ],
    );

    blocTest<LedgerBloc, LedgerState>(
      'LedgerCalculate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.calculateLedger(),
      ).thenThrow(dioError('Already running')),
      build: () => LedgerBloc(restClient),
      act: (bloc) => bloc.add(LedgerCalculate()),
      expect: () => [
        ledgerState(LedgerStatus.loading),
        ledgerState(LedgerStatus.failure, message: 'Already running'),
      ],
    );
  });
}

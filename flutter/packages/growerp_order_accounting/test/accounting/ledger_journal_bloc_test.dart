import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// LedgerJournalFetch is throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<LedgerJournalState> journalState(
  LedgerJournalStatus status, {
  List<LedgerJournal>? journals,
  String? message,
}) {
  var m = isA<LedgerJournalState>().having((s) => s.status, 'status', status);
  if (journals != null) {
    m = m.having((s) => s.ledgerJournals, 'ledgerJournals', journals);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final journal1 = LedgerJournal(journalId: 'J1', journalName: 'Opening');
  final journal2 = LedgerJournal(journalId: 'J2', journalName: 'Year end');

  setUp(() => restClient = MockRestClient());

  group('LedgerJournalFetch', () {
    blocTest<LedgerJournalBloc, LedgerJournalState>(
      'LedgerJournalFetch_initial_emitsFirstPage',
      setUp: () =>
          when(
            () => restClient.getLedgerJournal(
              start: 0,
              searchString: '',
              limit: 20,
            ),
          ).thenAnswer(
            (_) async => LedgerJournals(ledgerJournals: [journal1, journal2]),
          ),
      build: () => LedgerJournalBloc(restClient),
      act: (bloc) => bloc.add(const LedgerJournalFetch()),
      wait: fetchWait,
      expect: () => [
        journalState(
          LedgerJournalStatus.success,
          journals: [journal1, journal2],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<LedgerJournalBloc, LedgerJournalState>(
      'LedgerJournalFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () =>
            restClient.getLedgerJournal(start: 1, searchString: '', limit: 20),
      ).thenAnswer((_) async => LedgerJournals(ledgerJournals: [journal2])),
      build: () => LedgerJournalBloc(restClient),
      seed: () => LedgerJournalState(
        status: LedgerJournalStatus.success,
        ledgerJournals: [journal1],
      ),
      act: (bloc) => bloc.add(const LedgerJournalFetch()),
      wait: fetchWait,
      expect: () => [
        journalState(
          LedgerJournalStatus.success,
          journals: [journal1, journal2],
        ),
      ],
    );

    blocTest<LedgerJournalBloc, LedgerJournalState>(
      'LedgerJournalFetch_restThrowsDio_emitsFailureAndClearsList',
      setUp: () => when(
        () =>
            restClient.getLedgerJournal(start: 0, searchString: '', limit: 20),
      ).thenThrow(dioError('Journal service down')),
      build: () => LedgerJournalBloc(restClient),
      act: (bloc) => bloc.add(const LedgerJournalFetch()),
      wait: fetchWait,
      expect: () => [
        journalState(
          LedgerJournalStatus.failure,
          journals: [],
          message: 'Journal service down',
        ),
      ],
    );
  });

  group('LedgerJournalSearchChanged', () {
    blocTest<LedgerJournalBloc, LedgerJournalState>(
      'LedgerJournalSearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () => when(
        () => restClient.getLedgerJournal(
          start: 0,
          searchString: 'Ope',
          limit: 20,
        ),
      ).thenAnswer((_) async => LedgerJournals(ledgerJournals: [journal1])),
      build: () => LedgerJournalBloc(restClient),
      act: (bloc) =>
          bloc.add(const LedgerJournalSearchChanged(searchString: 'Ope')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        journalState(LedgerJournalStatus.success, journals: [journal1]),
      ],
    );
  });

  group('LedgerJournalUpdate', () {
    final changed = journal2.copyWith(journalName: 'Year end 2026');
    final newJournal = LedgerJournal(journalName: 'Correction');
    final created = newJournal.copyWith(journalId: 'J3');

    blocTest<LedgerJournalBloc, LedgerJournalState>(
      'LedgerJournalUpdate_existing_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateLedgerJournal(ledgerJournal: changed),
      ).thenAnswer((_) async => changed),
      build: () => LedgerJournalBloc(restClient),
      seed: () => LedgerJournalState(
        status: LedgerJournalStatus.success,
        ledgerJournals: [journal1, journal2],
      ),
      act: (bloc) => bloc.add(LedgerJournalUpdate(changed)),
      expect: () => [
        journalState(
          LedgerJournalStatus.success,
          journals: [journal1, changed],
          message: 'ledgerJournalUpdateSuccess',
        ),
      ],
    );

    blocTest<LedgerJournalBloc, LedgerJournalState>(
      'LedgerJournalUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createLedgerJournal(ledgerJournal: newJournal),
      ).thenAnswer((_) async => created),
      build: () => LedgerJournalBloc(restClient),
      seed: () => LedgerJournalState(
        status: LedgerJournalStatus.success,
        ledgerJournals: [journal1],
      ),
      act: (bloc) => bloc.add(LedgerJournalUpdate(newJournal)),
      expect: () => [
        journalState(
          LedgerJournalStatus.success,
          journals: [created, journal1],
          message: 'ledgerJournalAddSuccess:Correction',
        ),
      ],
    );

    blocTest<LedgerJournalBloc, LedgerJournalState>(
      'LedgerJournalUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createLedgerJournal(ledgerJournal: newJournal),
      ).thenThrow(dioError('Not allowed')),
      build: () => LedgerJournalBloc(restClient),
      act: (bloc) => bloc.add(LedgerJournalUpdate(newJournal)),
      expect: () => [
        journalState(LedgerJournalStatus.failure, message: 'Not allowed'),
      ],
    );
  });
}

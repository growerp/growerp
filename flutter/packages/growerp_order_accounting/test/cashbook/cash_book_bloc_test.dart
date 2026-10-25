import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// CashBookFetch is throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<CashBookState> cashBookState(
  CashBookStatus status, {
  List<CashBookEntry>? entries,
  String? message,
}) {
  var m = isA<CashBookState>().having((s) => s.status, 'status', status);
  if (entries != null) m = m.having((s) => s.entries, 'entries', entries);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final sale = CashBookEntry(
    transactionId: 'T1',
    amount: Decimal.parse('100'),
    description: 'sale',
  );
  final rent = CashBookEntry(
    transactionId: 'T2',
    isIncome: false,
    amount: Decimal.parse('40'),
    description: 'rent',
  );
  final salesAccount = GlAccount(glAccountId: 'G4000', accountName: 'Sales');
  final rentAccount = GlAccount(glAccountId: 'G6000', accountName: 'Rent');

  setUp(() => restClient = MockRestClient());

  group('CashBookFetch', () {
    blocTest<CashBookBloc, CashBookState>(
      'CashBookFetch_incomeOnly_filtersAndRemembersDirection',
      setUp: () => when(
        () => restClient.getCashBookEntry(
          start: 0,
          limit: 20,
          searchString: '',
          isIncome: true,
        ),
      ).thenAnswer((_) async => CashBookEntries(cashBookEntries: [sale])),
      build: () => CashBookBloc(restClient),
      act: (bloc) => bloc.add(const CashBookFetch(isIncome: true)),
      wait: fetchWait,
      expect: () => [
        cashBookState(CashBookStatus.success, entries: [sale])
            .having((s) => s.isIncome, 'isIncome', true)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<CashBookBloc, CashBookState>(
      'CashBookFetch_bothDirections_clearsDirectionFilter',
      setUp: () => when(
        () =>
            restClient.getCashBookEntry(start: 0, limit: 20, searchString: ''),
      ).thenAnswer((_) async => CashBookEntries(cashBookEntries: [sale, rent])),
      build: () => CashBookBloc(restClient),
      seed: () => CashBookState(isIncome: true),
      act: (bloc) => bloc.add(const CashBookFetch(refresh: true)),
      wait: fetchWait,
      expect: () => [
        cashBookState(
          CashBookStatus.success,
          entries: [sale, rent],
        ).having((s) => s.isIncome, 'isIncome', isNull),
      ],
    );

    blocTest<CashBookBloc, CashBookState>(
      'CashBookFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () =>
            restClient.getCashBookEntry(start: 1, limit: 20, searchString: ''),
      ).thenAnswer((_) async => CashBookEntries(cashBookEntries: [rent])),
      build: () => CashBookBloc(restClient),
      seed: () =>
          CashBookState(status: CashBookStatus.success, entries: [sale]),
      act: (bloc) => bloc.add(const CashBookFetch()),
      wait: fetchWait,
      expect: () => [
        cashBookState(CashBookStatus.success, entries: [sale, rent]),
      ],
    );

    blocTest<CashBookBloc, CashBookState>(
      'CashBookFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () =>
            restClient.getCashBookEntry(start: 0, limit: 20, searchString: ''),
      ).thenThrow(dioError('Cash book down')),
      build: () => CashBookBloc(restClient),
      act: (bloc) => bloc.add(const CashBookFetch()),
      wait: fetchWait,
      expect: () => [
        cashBookState(CashBookStatus.failure, message: 'Cash book down'),
      ],
    );
  });

  group('CashBookSearchChanged', () {
    blocTest<CashBookBloc, CashBookState>(
      'CashBookSearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () => when(
        () => restClient.getCashBookEntry(
          start: 0,
          limit: 20,
          searchString: 'ren',
          isIncome: false,
        ),
      ).thenAnswer((_) async => CashBookEntries(cashBookEntries: [rent])),
      build: () => CashBookBloc(restClient),
      act: (bloc) => bloc.add(
        const CashBookSearchChanged(searchString: 'ren', isIncome: false),
      ),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        cashBookState(CashBookStatus.success, entries: [rent]),
      ],
    );
  });

  group('CashBookUpdate', () {
    final changed = rent.copyWith(description: 'office rent');
    final newEntry = CashBookEntry(
      amount: Decimal.parse('5'),
      description: 'tip',
    );
    final created = newEntry.copyWith(transactionId: 'T3');

    blocTest<CashBookBloc, CashBookState>(
      'CashBookUpdate_existing_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateCashBookEntry(cashBookEntry: changed),
      ).thenAnswer((_) async => changed),
      build: () => CashBookBloc(restClient),
      seed: () =>
          CashBookState(status: CashBookStatus.success, entries: [sale, rent]),
      act: (bloc) => bloc.add(CashBookUpdate(changed)),
      expect: () => [
        cashBookState(
          CashBookStatus.success,
          entries: [sale, changed],
          message: 'cashBookUpdateSuccess',
        ),
      ],
    );

    blocTest<CashBookBloc, CashBookState>(
      'CashBookUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createCashBookEntry(cashBookEntry: newEntry),
      ).thenAnswer((_) async => created),
      build: () => CashBookBloc(restClient),
      seed: () =>
          CashBookState(status: CashBookStatus.success, entries: [sale]),
      act: (bloc) => bloc.add(CashBookUpdate(newEntry)),
      expect: () => [
        cashBookState(
          CashBookStatus.success,
          entries: [created, sale],
          message: 'cashBookAddSuccess',
        ),
      ],
    );

    blocTest<CashBookBloc, CashBookState>(
      'CashBookUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createCashBookEntry(cashBookEntry: newEntry),
      ).thenThrow(dioError('Category missing')),
      build: () => CashBookBloc(restClient),
      act: (bloc) => bloc.add(CashBookUpdate(newEntry)),
      expect: () => [
        cashBookState(CashBookStatus.failure, message: 'Category missing'),
      ],
    );
  });

  group('CashBookDelete', () {
    blocTest<CashBookBloc, CashBookState>(
      'CashBookDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteCashBookEntry(transactionId: 'T1'),
      ).thenAnswer((_) async {}),
      build: () => CashBookBloc(restClient),
      seed: () =>
          CashBookState(status: CashBookStatus.success, entries: [sale, rent]),
      act: (bloc) => bloc.add(CashBookDelete(sale)),
      expect: () => [
        cashBookState(
          CashBookStatus.success,
          entries: [rent],
          message: 'cashBookDeleteSuccess',
        ),
      ],
    );

    blocTest<CashBookBloc, CashBookState>(
      'CashBookDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteCashBookEntry(transactionId: 'T1'),
      ).thenThrow(dioError('Period closed')),
      build: () => CashBookBloc(restClient),
      seed: () =>
          CashBookState(status: CashBookStatus.success, entries: [sale]),
      act: (bloc) => bloc.add(CashBookDelete(sale)),
      expect: () => [
        cashBookState(CashBookStatus.failure, message: 'Period closed'),
      ],
    );
  });

  group('CashBookCategoriesFetch', () {
    void stubCategories() {
      when(
        () => restClient.getCashBookCategory(isIncome: true, usedOnly: true),
      ).thenAnswer((_) async => GlAccounts(glAccounts: [salesAccount]));
      when(
        () => restClient.getCashBookCategory(isIncome: false, usedOnly: true),
      ).thenAnswer((_) async => GlAccounts(glAccounts: [rentAccount]));
    }

    blocTest<CashBookBloc, CashBookState>(
      'CashBookCategoriesFetch_first_loadsUsedIncomeAndExpenseCategories',
      setUp: stubCategories,
      build: () => CashBookBloc(restClient),
      act: (bloc) => bloc.add(const CashBookCategoriesFetch()),
      expect: () => [
        cashBookState(CashBookStatus.categoriesSuccess)
            .having((s) => s.incomeCategories, 'income', [salesAccount])
            .having((s) => s.expenseCategories, 'expenses', [rentAccount]),
      ],
    );

    blocTest<CashBookBloc, CashBookState>(
      'CashBookCategoriesFetch_alreadyLoaded_skipsUnlessRefresh',
      build: () => CashBookBloc(restClient),
      seed: () => CashBookState(incomeCategories: [salesAccount]),
      act: (bloc) => bloc.add(const CashBookCategoriesFetch()),
      expect: () => <CashBookState>[],
      verify: (_) => verifyZeroInteractions(restClient),
    );

    blocTest<CashBookBloc, CashBookState>(
      'CashBookCategoriesFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getCashBookCategory(isIncome: true, usedOnly: true),
      ).thenThrow(dioError('No access')),
      build: () => CashBookBloc(restClient),
      act: (bloc) => bloc.add(const CashBookCategoriesFetch()),
      expect: () => [
        cashBookState(CashBookStatus.failure, message: 'No access'),
      ],
    );
  });
}

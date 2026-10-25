import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<CashBookCategoryState> categoryState(
  CashBookCategoryStatus status, {
  List<GlAccount>? income,
  List<GlAccount>? expenses,
  String? message,
}) {
  var m = isA<CashBookCategoryState>().having(
    (s) => s.status,
    'status',
    status,
  );
  if (income != null) {
    m = m.having((s) => s.incomeCategories, 'incomeCategories', income);
  }
  if (expenses != null) {
    m = m.having((s) => s.expenseCategories, 'expenseCategories', expenses);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final salesAccount = GlAccount(glAccountId: 'G4000', accountName: 'Sales');
  final rentAccount = GlAccount(glAccountId: 'G6000', accountName: 'Rent');

  setUp(() => restClient = MockRestClient());

  group('CashBookCategoryFetch', () {
    blocTest<CashBookCategoryBloc, CashBookCategoryState>(
      'CashBookCategoryFetch_initial_loadsAllIncomeAndExpenseAccounts',
      setUp: () {
        when(
          () => restClient.getCashBookCategory(isIncome: true),
        ).thenAnswer((_) async => GlAccounts(glAccounts: [salesAccount]));
        when(
          () => restClient.getCashBookCategory(isIncome: false),
        ).thenAnswer((_) async => GlAccounts(glAccounts: [rentAccount]));
      },
      build: () => CashBookCategoryBloc(restClient),
      act: (bloc) => bloc.add(const CashBookCategoryFetch()),
      expect: () => [
        categoryState(CashBookCategoryStatus.loading),
        categoryState(
          CashBookCategoryStatus.success,
          income: [salesAccount],
          expenses: [rentAccount],
        ),
      ],
    );

    blocTest<CashBookCategoryBloc, CashBookCategoryState>(
      'CashBookCategoryFetch_loadedWithoutRefresh_doesNothing',
      build: () => CashBookCategoryBloc(restClient),
      seed: () => CashBookCategoryState(status: CashBookCategoryStatus.success),
      act: (bloc) => bloc.add(const CashBookCategoryFetch()),
      expect: () => <CashBookCategoryState>[],
      verify: (_) => verifyZeroInteractions(restClient),
    );

    blocTest<CashBookCategoryBloc, CashBookCategoryState>(
      'CashBookCategoryFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getCashBookCategory(isIncome: true),
      ).thenThrow(dioError('No access')),
      build: () => CashBookCategoryBloc(restClient),
      act: (bloc) => bloc.add(const CashBookCategoryFetch()),
      expect: () => [
        categoryState(CashBookCategoryStatus.loading),
        categoryState(CashBookCategoryStatus.failure, message: 'No access'),
      ],
    );
  });

  group('CashBookCategoryUpdate', () {
    final unused = rentAccount.copyWith(accountName: 'Office rent');

    blocTest<CashBookCategoryBloc, CashBookCategoryState>(
      'CashBookCategoryUpdate_rename_replacesInMatchingList',
      setUp: () => when(
        () => restClient.updateCashBookCategory(
          glAccountId: 'G6000',
          accountName: 'Office rent',
        ),
      ).thenAnswer((_) async => unused),
      build: () => CashBookCategoryBloc(restClient),
      seed: () => CashBookCategoryState(
        status: CashBookCategoryStatus.success,
        incomeCategories: [salesAccount],
        expenseCategories: [rentAccount],
      ),
      act: (bloc) => bloc.add(
        CashBookCategoryUpdate(rentAccount, accountName: 'Office rent'),
      ),
      expect: () => [
        categoryState(
          CashBookCategoryStatus.success,
          income: [salesAccount],
          expenses: [unused],
          message: 'cashBookCategoryUpdateSuccess',
        ),
      ],
    );

    blocTest<CashBookCategoryBloc, CashBookCategoryState>(
      'CashBookCategoryUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateCashBookCategory(
          glAccountId: 'G6000',
          isUsed: false,
        ),
      ).thenThrow(dioError('Account has postings')),
      build: () => CashBookCategoryBloc(restClient),
      act: (bloc) =>
          bloc.add(CashBookCategoryUpdate(rentAccount, isUsed: false)),
      expect: () => [
        categoryState(
          CashBookCategoryStatus.failure,
          message: 'Account has postings',
        ),
      ],
    );
  });

  group('CashBookCategoryCreate', () {
    final tips = GlAccount(glAccountId: 'G4100', accountName: 'Tips');

    blocTest<CashBookCategoryBloc, CashBookCategoryState>(
      'CashBookCategoryCreate_income_insertsFirstInIncomeOnly',
      setUp: () => when(
        () => restClient.createCashBookCategory(
          accountName: 'Tips',
          isIncome: true,
        ),
      ).thenAnswer((_) async => tips),
      build: () => CashBookCategoryBloc(restClient),
      seed: () => CashBookCategoryState(
        status: CashBookCategoryStatus.success,
        incomeCategories: [salesAccount],
        expenseCategories: [rentAccount],
      ),
      act: (bloc) => bloc.add(
        const CashBookCategoryCreate(accountName: 'Tips', isIncome: true),
      ),
      expect: () => [
        categoryState(
          CashBookCategoryStatus.success,
          income: [tips, salesAccount],
          expenses: [rentAccount],
          message: 'cashBookCategoryAddSuccess',
        ),
      ],
    );

    blocTest<CashBookCategoryBloc, CashBookCategoryState>(
      'CashBookCategoryCreate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createCashBookCategory(
          accountName: 'Tips',
          isIncome: true,
        ),
      ).thenThrow(dioError('Name already used')),
      build: () => CashBookCategoryBloc(restClient),
      act: (bloc) => bloc.add(
        const CashBookCategoryCreate(accountName: 'Tips', isIncome: true),
      ),
      expect: () => [
        categoryState(
          CashBookCategoryStatus.failure,
          message: 'Name already used',
        ),
      ],
    );
  });
}

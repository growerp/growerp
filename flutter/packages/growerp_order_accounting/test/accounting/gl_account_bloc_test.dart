import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// GlAccountFetch is throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<GlAccountState> glState(
  GlAccountStatus status, {
  List<GlAccount>? glAccounts,
  String? message,
}) {
  var m = isA<GlAccountState>().having((s) => s.status, 'status', status);
  if (glAccounts != null) {
    m = m.having((s) => s.glAccounts, 'glAccounts', glAccounts);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final cash = GlAccount(
    glAccountId: 'G1',
    accountCode: '1000',
    accountName: 'Cash',
  );
  final bank = GlAccount(
    glAccountId: 'G2',
    accountCode: '1010',
    accountName: 'Bank',
  );

  setUpAll(() => registerFallbackValue(<GlAccount>[]));
  setUp(() => restClient = MockRestClient());

  void stubGetGlAccount({
    int start = 0,
    String searchString = '',
    bool trialBalance = false,
    required Future<GlAccounts> Function(Invocation) answer,
  }) => when(
    () => restClient.getGlAccount(
      start: start,
      limit: 20,
      searchString: searchString,
      trialBalance: trialBalance,
    ),
  ).thenAnswer(answer);

  group('GlAccountFetch', () {
    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountFetch_initial_clearsListThenEmitsFirstPage',
      setUp: () => stubGetGlAccount(
        answer: (_) async =>
            GlAccounts(glAccounts: [cash, bank], initialUploadAllowed: false),
      ),
      build: () => GlAccountBloc(restClient),
      act: (bloc) => bloc.add(const GlAccountFetch()),
      wait: fetchWait,
      expect: () => [
        glState(GlAccountStatus.loading, glAccounts: []),
        glState(GlAccountStatus.success, glAccounts: [cash, bank])
            .having((s) => s.hasReachedMax, 'hasReachedMax', true)
            .having(
              (s) => s.initialUploadAllowed,
              'initialUploadAllowed',
              false,
            ),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountFetch_nextPageEmpty_keepsListAndReachesMax',
      setUp: () =>
          stubGetGlAccount(start: 1, answer: (_) async => GlAccounts()),
      build: () => GlAccountBloc(restClient),
      seed: () =>
          GlAccountState(status: GlAccountStatus.success, glAccounts: [cash]),
      act: (bloc) => bloc.add(const GlAccountFetch()),
      wait: fetchWait,
      expect: () => [
        glState(
          GlAccountStatus.success,
          glAccounts: [cash],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountFetch_trialBalance_alwaysRestartsFromFirstPage',
      setUp: () => stubGetGlAccount(
        trialBalance: true,
        answer: (_) async => GlAccounts(glAccounts: [bank]),
      ),
      build: () => GlAccountBloc(restClient),
      seed: () =>
          GlAccountState(status: GlAccountStatus.success, glAccounts: [cash]),
      act: (bloc) => bloc.add(const GlAccountFetch(trialBalance: true)),
      wait: fetchWait,
      expect: () => [
        glState(GlAccountStatus.loading, glAccounts: []),
        glState(GlAccountStatus.success, glAccounts: [bank]),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountFetch_restThrowsDio_emitsFailure',
      setUp: () => stubGetGlAccount(
        answer: (_) async => throw dioError('Ledger service down'),
      ),
      build: () => GlAccountBloc(restClient),
      act: (bloc) => bloc.add(const GlAccountFetch()),
      wait: fetchWait,
      expect: () => [
        glState(GlAccountStatus.loading),
        glState(GlAccountStatus.failure, message: 'Ledger service down'),
      ],
    );
  });

  group('GlAccountSearchChanged', () {
    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountSearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () => stubGetGlAccount(
        searchString: 'Ban',
        answer: (_) async => GlAccounts(glAccounts: [bank]),
      ),
      build: () => GlAccountBloc(restClient),
      seed: () => GlAccountState(
        status: GlAccountStatus.success,
        glAccounts: [cash, bank],
      ),
      act: (bloc) =>
          bloc.add(const GlAccountSearchChanged(searchString: 'Ban')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        glState(GlAccountStatus.loading, glAccounts: []),
        glState(GlAccountStatus.success, glAccounts: [bank]),
      ],
    );
  });

  group('GlAccountUpdate', () {
    final changed = bank.copyWith(accountName: 'Bank BKK');
    final newAccount = GlAccount(accountCode: '1020', accountName: 'Petty');
    final created = newAccount.copyWith(glAccountId: 'G3');

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountUpdate_existing_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateGlAccount(glAccount: changed),
      ).thenAnswer((_) async => changed),
      build: () => GlAccountBloc(restClient),
      seed: () => GlAccountState(
        status: GlAccountStatus.success,
        glAccounts: [cash, bank],
      ),
      act: (bloc) => bloc.add(GlAccountUpdate(changed)),
      expect: () => [
        glState(GlAccountStatus.glAccountLoading),
        glState(
          GlAccountStatus.success,
          glAccounts: [cash, changed],
          message: 'glAccountUpdateSuccess:Bank BKK',
        ),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createGlAccount(glAccount: newAccount),
      ).thenAnswer((_) async => created),
      build: () => GlAccountBloc(restClient),
      seed: () =>
          GlAccountState(status: GlAccountStatus.success, glAccounts: [cash]),
      act: (bloc) => bloc.add(GlAccountUpdate(newAccount)),
      expect: () => [
        glState(GlAccountStatus.glAccountLoading),
        glState(
          GlAccountStatus.success,
          glAccounts: [created, cash],
          message: 'glAccountAddSuccess:Petty',
        ),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountUpdate_restThrowsDio_emitsFailureAndClearsList',
      setUp: () => when(
        () => restClient.createGlAccount(glAccount: newAccount),
      ).thenThrow(dioError('Code already used')),
      build: () => GlAccountBloc(restClient),
      seed: () =>
          GlAccountState(status: GlAccountStatus.success, glAccounts: [cash]),
      act: (bloc) => bloc.add(GlAccountUpdate(newAccount)),
      expect: () => [
        glState(GlAccountStatus.glAccountLoading),
        glState(
          GlAccountStatus.failure,
          glAccounts: [],
          message: 'Code already used',
        ),
      ],
    );
  });

  group('GlAccountClassesFetch / GlAccountTypesFetch', () {
    const assetClass = AccountClass(description: 'Asset');
    final cashType = AccountType(description: 'Cash');

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountClassesFetch_success_setsClasses',
      setUp: () => when(
        () => restClient.getAccountClass(searchString: '', limit: 20),
      ).thenAnswer((_) async => AccountClasses(accountClasses: [assetClass])),
      build: () => GlAccountBloc(restClient),
      act: (bloc) => bloc.add(const GlAccountClassesFetch()),
      expect: () => [
        glState(
          GlAccountStatus.success,
        ).having((s) => s.accountClasses, 'accountClasses', [assetClass]),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountTypesFetch_success_setsTypes',
      setUp: () => when(
        () => restClient.getAccountType(searchString: 'Ca', limit: 5),
      ).thenAnswer((_) async => AccountTypes(accountTypes: [cashType])),
      build: () => GlAccountBloc(restClient),
      act: (bloc) =>
          bloc.add(const GlAccountTypesFetch(searchString: 'Ca', limit: 5)),
      expect: () => [
        glState(
          GlAccountStatus.success,
        ).having((s) => s.accountTypes, 'accountTypes', [cashType]),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountClassesFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getAccountClass(searchString: '', limit: 20),
      ).thenThrow(dioError('No access')),
      build: () => GlAccountBloc(restClient),
      act: (bloc) => bloc.add(const GlAccountClassesFetch()),
      expect: () => [glState(GlAccountStatus.failure, message: 'No access')],
    );
  });

  group('GlAccountUpload', () {
    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountUpload_csvWithBlankLinesAndHeader_importsAccountRows',
      setUp: () => when(
        () => restClient.importGlAccounts(any(), periodYear: '2026'),
      ).thenAnswer((_) async => '{}'),
      build: () => GlAccountBloc(restClient),
      act: (bloc) => bloc.add(
        const GlAccountUpload(
          '\n'
              'id,name,debit,class,type,balance\n'
              '1000,Cash,true,Asset,,150.25\n'
              '  \n'
              '2000,Payables,FALSE,,Liability,\n',
          '2026',
        ),
      ),
      expect: () => [
        glState(GlAccountStatus.loading),
        glState(GlAccountStatus.success, message: 'glAccountUploadSuccess'),
      ],
      verify: (_) {
        final imported =
            verify(
                  () => restClient.importGlAccounts(
                    captureAny(),
                    periodYear: '2026',
                  ),
                ).captured.single
                as List<GlAccount>;
        expect(imported.map((a) => a.accountCode), ['1000', '2000']);
        expect(imported.first.isDebit, isTrue);
        expect(imported.first.accountClass?.description, 'Asset');
        expect(imported.first.postedBalance, Decimal.parse('150.25'));
        expect(imported.last.isDebit, isFalse);
        expect(imported.last.accountType?.description, 'Liability');
        expect(imported.last.postedBalance, isNull);
      },
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountUpload_backendWarning_showsBackendMessage',
      setUp: () => when(
        () => restClient.importGlAccounts(any(), periodYear: '2026'),
      ).thenAnswer((_) async => '{"messages": "Initial balance not posted"}'),
      build: () => GlAccountBloc(restClient),
      act: (bloc) =>
          bloc.add(const GlAccountUpload('1000,Cash,true,,,\n', '2026')),
      expect: () => [
        glState(GlAccountStatus.loading),
        glState(GlAccountStatus.success, message: 'Initial balance not posted'),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountUpload_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.importGlAccounts(any(), periodYear: '2026'),
      ).thenThrow(dioError('Ledger has postings')),
      build: () => GlAccountBloc(restClient),
      act: (bloc) =>
          bloc.add(const GlAccountUpload('1000,Cash,true,,,\n', '2026')),
      expect: () => [
        glState(GlAccountStatus.loading),
        glState(GlAccountStatus.failure, message: 'Ledger has postings'),
      ],
    );
  });

  group('GlAccountDownload', () {
    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountDownload_fileText_emitsDownloadedCsv',
      setUp: () => when(
        () => restClient.downloadGlAccounts(),
      ).thenAnswer((_) async => '{"fileText": "id,name\\n1000,Cash"}'),
      build: () => GlAccountBloc(restClient),
      act: (bloc) => bloc.add(GlAccountDownload()),
      expect: () => [
        glState(GlAccountStatus.loading),
        glState(
          GlAccountStatus.downloaded,
        ).having((s) => s.csvFile, 'csvFile', 'id,name\n1000,Cash'),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountDownload_noFileText_emitsFailureWithBackendMessage',
      setUp: () => when(
        () => restClient.downloadGlAccounts(),
      ).thenAnswer((_) async => '{"messages": "No accounts"}'),
      build: () => GlAccountBloc(restClient),
      act: (bloc) => bloc.add(GlAccountDownload()),
      expect: () => [
        glState(GlAccountStatus.loading),
        glState(GlAccountStatus.failure, message: 'No accounts'),
      ],
    );

    blocTest<GlAccountBloc, GlAccountState>(
      'GlAccountDownload_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.downloadGlAccounts(),
      ).thenThrow(dioError('Nope')),
      build: () => GlAccountBloc(restClient),
      act: (bloc) => bloc.add(GlAccountDownload()),
      expect: () => [
        glState(GlAccountStatus.loading),
        glState(GlAccountStatus.failure, message: 'Nope'),
      ],
    );
  });
}

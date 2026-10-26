import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// CompanyFetch is throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<CompanyState> companyState(
  CompanyStatus status, {
  List<Company>? companies,
  String? message,
}) {
  var m = isA<CompanyState>().having((s) => s.status, 'status', status);
  if (companies != null) {
    m = m.having((s) => s.companies, 'companies', companies);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  void stubGetCompany({
    int start = 0,
    String searchString = '',
    required Future<Companies> Function(Invocation) answer,
  }) => when(
    () => restClient.getCompany(
      role: Role.supplier,
      companyPartyId: '',
      ownerPartyId: '',
      searchString: searchString,
      isForDropDown: false,
      start: start,
      limit: 20,
    ),
  ).thenAnswer(answer);

  group('CompanyFetch', () {
    blocTest<CompanyBloc, CompanyState>(
      'CompanyFetch_initial_requestsRoleAndEmitsFirstPage',
      setUp: () => stubGetCompany(
        answer: (_) async => Companies(companies: [company1, company2]),
      ),
      build: () => CompanyBloc(restClient, Role.supplier),
      act: (bloc) => bloc.add(const CompanyFetch()),
      wait: fetchWait,
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(CompanyStatus.success, companies: [company1, company2])
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<CompanyBloc, CompanyState>(
      'CompanyFetch_nextPage_appendsFromCurrentLength',
      setUp: () => stubGetCompany(
        start: 1,
        answer: (_) async => Companies(companies: [company2]),
      ),
      build: () => CompanyBloc(restClient, Role.supplier),
      seed: () =>
          CompanyState(status: CompanyStatus.success, companies: [company1]),
      act: (bloc) => bloc.add(const CompanyFetch()),
      wait: fetchWait,
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(CompanyStatus.success, companies: [company1, company2]),
      ],
    );

    blocTest<CompanyBloc, CompanyState>(
      'CompanyFetch_mainOnly_usesMainCompaniesEndpoint',
      setUp: () => when(
        () => restClient.getCompanies(start: 0, limit: 20),
      ).thenAnswer((_) async => Companies(companies: [company1])),
      build: () => CompanyBloc(restClient, null),
      act: (bloc) => bloc.add(const CompanyFetch(mainOnly: true)),
      wait: fetchWait,
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(CompanyStatus.success, companies: [company1]),
      ],
    );

    blocTest<CompanyBloc, CompanyState>(
      'CompanyFetch_restThrowsDio_emitsFailure',
      setUp: () => stubGetCompany(
        answer: (_) async => throw dioError('Company service down'),
      ),
      build: () => CompanyBloc(restClient, Role.supplier),
      act: (bloc) => bloc.add(const CompanyFetch()),
      wait: fetchWait,
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(CompanyStatus.failure, message: 'Company service down'),
      ],
    );
  });

  group('CompanySearchChanged', () {
    blocTest<CompanyBloc, CompanyState>(
      'CompanySearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () => stubGetCompany(
        searchString: 'Acm',
        answer: (_) async => Companies(companies: [company1]),
      ),
      build: () => CompanyBloc(restClient, Role.supplier),
      seed: () => CompanyState(
        status: CompanyStatus.success,
        companies: [company1, company2],
      ),
      act: (bloc) => bloc.add(const CompanySearchChanged(searchString: 'Acm')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(CompanyStatus.success, companies: [company1]),
      ],
    );
  });

  group('CompanyUpdate', () {
    final changed = company2.copyWith(name: 'Globex Corp');
    final newCompany = Company(name: 'Initech');
    final created = newCompany.copyWith(partyId: 'C3');

    blocTest<CompanyBloc, CompanyState>(
      'CompanyUpdate_existingCompany_movesUpdatedCompanyToTop',
      setUp: () => when(
        () => restClient.updateCompany(company: changed),
      ).thenAnswer((_) async => changed),
      build: () => CompanyBloc(restClient, Role.supplier),
      seed: () => CompanyState(
        status: CompanyStatus.success,
        companies: [company1, company2],
      ),
      act: (bloc) => bloc.add(CompanyUpdate(changed)),
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(
          CompanyStatus.success,
          companies: [changed, company1],
          message: 'companyUpdateSuccess:Globex Corp',
        ),
      ],
    );

    blocTest<CompanyBloc, CompanyState>(
      'CompanyUpdate_newCompany_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createCompany(company: newCompany),
      ).thenAnswer((_) async => created),
      build: () => CompanyBloc(restClient, Role.supplier),
      seed: () =>
          CompanyState(status: CompanyStatus.success, companies: [company1]),
      act: (bloc) => bloc.add(CompanyUpdate(newCompany)),
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(
          CompanyStatus.success,
          companies: [created, company1],
          message: 'companyAddSuccess:Initech',
        ),
      ],
    );

    blocTest<CompanyBloc, CompanyState>(
      'CompanyUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateCompany(company: changed),
      ).thenThrow(dioError('Not allowed')),
      build: () => CompanyBloc(restClient, Role.supplier),
      seed: () =>
          CompanyState(status: CompanyStatus.success, companies: [company2]),
      act: (bloc) => bloc.add(CompanyUpdate(changed)),
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(CompanyStatus.failure, message: 'Not allowed'),
      ],
    );
  });

  // https://github.com/growerp/growerp/issues/35
  group('CompanyDelete', () {
    blocTest<CompanyBloc, CompanyState>(
      'CompanyDelete_existing_removesItFromTheList',
      setUp: () => when(
        () => restClient.deleteCompany(partyId: company1.partyId!),
      ).thenAnswer((_) async => company1),
      build: () => CompanyBloc(restClient, Role.supplier),
      seed: () => CompanyState(
        status: CompanyStatus.success,
        companies: [company1, company2],
      ),
      act: (bloc) => bloc.add(CompanyDelete(company1)),
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(
          CompanyStatus.success,
          companies: [company2],
          message: 'companyDeleteSuccess',
        ),
      ],
    );

    blocTest<CompanyBloc, CompanyState>(
      'CompanyDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteCompany(partyId: company1.partyId!),
      ).thenThrow(dioError('Not allowed')),
      build: () => CompanyBloc(restClient, Role.supplier),
      seed: () =>
          CompanyState(status: CompanyStatus.success, companies: [company1]),
      act: (bloc) => bloc.add(CompanyDelete(company1)),
      expect: () => [
        companyState(CompanyStatus.loading),
        companyState(CompanyStatus.failure, message: 'Not allowed'),
      ],
    );
  });
}

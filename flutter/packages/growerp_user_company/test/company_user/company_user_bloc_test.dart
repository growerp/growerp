import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// CompanyUserFetch is throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<CompanyUserState> companyUserState(
  CompanyUserStatus status, {
  List<CompanyUser>? companiesUsers,
  String? message,
}) {
  var m = isA<CompanyUserState>().having((s) => s.status, 'status', status);
  if (companiesUsers != null) {
    m = m.having((s) => s.companiesUsers, 'companiesUsers', companiesUsers);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  setUpAll(() => registerFallbackValue(<CompanyUser>[]));
  setUp(() => restClient = MockRestClient());

  CompanyUserBloc build() => CompanyUserBloc(restClient, Role.customer);

  group('CompanyUserFetch', () {
    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserFetch_list_requestsRoleAndEmitsFirstPage',
      setUp: () => when(
        () => restClient.getCompanyUser(
          role: Role.customer,
          searchString: '',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async =>
            CompaniesUsers(companiesUsers: [companyUser1, companyUser2]),
      ),
      build: build,
      act: (bloc) => bloc.add(const CompanyUserFetch()),
      wait: fetchWait,
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
          companiesUsers: [companyUser1, companyUser2],
        ).having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () => restClient.getCompanyUser(
          role: Role.customer,
          searchString: '',
          start: 1,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => CompaniesUsers(companiesUsers: [companyUser2]),
      ),
      build: build,
      seed: () => CompanyUserState(
        status: CompanyUserStatus.success,
        companiesUsers: [companyUser1],
      ),
      act: (bloc) => bloc.add(const CompanyUserFetch()),
      wait: fetchWait,
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
          companiesUsers: [companyUser1, companyUser2],
        ),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserFetch_companyById_setsCompany',
      setUp: () => when(
        () => restClient.getCompany(companyPartyId: 'C1'),
      ).thenAnswer((_) async => Companies(companies: [company1])),
      build: build,
      act: (bloc) => bloc.add(
        const CompanyUserFetch(type: PartyType.company, partyId: 'C1'),
      ),
      wait: fetchWait,
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
        ).having((s) => s.company, 'company', company1),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserFetch_userById_setsUser',
      setUp: () => when(
        () => restClient.getUser(partyId: 'U1'),
      ).thenAnswer((_) async => Users(users: [user1])),
      build: build,
      act: (bloc) =>
          bloc.add(const CompanyUserFetch(type: PartyType.user, partyId: 'U1')),
      wait: fetchWait,
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
        ).having((s) => s.user, 'user', user1),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getCompanyUser(
          role: Role.customer,
          searchString: '',
          start: 0,
          limit: 20,
        ),
      ).thenThrow(dioError('Party service down')),
      build: build,
      act: (bloc) => bloc.add(const CompanyUserFetch()),
      wait: fetchWait,
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.failure,
          message: 'Party service down',
        ),
      ],
    );
  });

  group('CompanyUserSearchChanged', () {
    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserSearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () => when(
        () => restClient.getCompanyUser(
          role: Role.customer,
          searchString: 'Acm',
          start: 0,
          limit: 20,
        ),
      ).thenAnswer(
        (_) async => CompaniesUsers(companiesUsers: [companyUser1]),
      ),
      build: build,
      seed: () => CompanyUserState(
        status: CompanyUserStatus.success,
        companiesUsers: [companyUser1, companyUser2],
      ),
      act: (bloc) =>
          bloc.add(const CompanyUserSearchChanged(searchString: 'Acm')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
          companiesUsers: [companyUser1],
        ),
      ],
    );
  });

  group('CompanyUserUpdate company', () {
    final changed = companyUser1.copyWith(name: 'Acme Inc');

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpdate_existingCompany_movesUpdatedCompanyToTop',
      setUp: () => when(
        () => restClient.updateCompany(company: changed.getCompany()!),
      ).thenAnswer((_) async => company1.copyWith(name: 'Acme Inc')),
      build: build,
      seed: () => CompanyUserState(
        status: CompanyUserStatus.success,
        companiesUsers: [companyUser2, companyUser1],
      ),
      act: (bloc) => bloc.add(CompanyUserUpdate(changed)),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
          message: 'companyUpdateSuccess:Acme Inc',
        ).having(
          (s) => s.companiesUsers.map((c) => c.name),
          'names',
          ['Acme Inc', 'Jane Roe'],
        ),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpdate_newCompany_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createCompany(
          company: Company(name: 'Initech'),
        ),
      ).thenAnswer((_) async => Company(partyId: 'C3', name: 'Initech')),
      build: build,
      act: (bloc) => bloc.add(
        CompanyUserUpdate(
          CompanyUser(type: PartyType.company, name: 'Initech'),
        ),
      ),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
          message: 'companyAddSuccess:Initech',
        ).having(
          (s) => s.companiesUsers.single.partyId,
          'partyId',
          'C3',
        ),
      ],
    );
  });

  group('CompanyUserUpdate user', () {
    final newUser = CompanyUser(type: PartyType.user, name: 'Max Power');
    final withCompany = CompanyUser(
      type: PartyType.user,
      name: 'Gavin Belson',
      company: Company(name: 'Hooli'),
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpdate_newUser_createsAndTakesBackendIds',
      setUp: () => when(
        () => restClient.createUser(user: newUser.getUser()!),
      ).thenAnswer(
        (_) async => User(partyId: 'U3', pseudoId: 'u3'),
      ),
      build: build,
      seed: () => CompanyUserState(
        status: CompanyUserStatus.success,
        companiesUsers: [companyUser1],
      ),
      act: (bloc) => bloc.add(CompanyUserUpdate(newUser)),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
          companiesUsers: [
            newUser.copyWith(partyId: 'U3', pseudoId: 'u3'),
            companyUser1,
          ],
          message: 'userAddSuccess:Max Power',
        ),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpdate_existingUser_replacesAndMovesToTop',
      setUp: () => when(
        () => restClient.updateUser(user: companyUser2.getUser()!),
      ).thenAnswer((_) async => User(partyId: 'U2', pseudoId: 'u2')),
      build: build,
      seed: () => CompanyUserState(
        status: CompanyUserStatus.success,
        companiesUsers: [companyUser1, companyUser2],
      ),
      act: (bloc) => bloc.add(CompanyUserUpdate(companyUser2)),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
          companiesUsers: [
            companyUser2.copyWith(pseudoId: 'u2'),
            companyUser1,
          ],
          message: 'userUpdateSuccess:Jane Roe',
        ),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpdate_newUserWithCompany_showsCompanyWithEmployee',
      setUp: () => when(
        () => restClient.createUser(user: withCompany.getUser()!),
      ).thenAnswer(
        (_) async => User(
          partyId: 'U4',
          company: Company(partyId: 'C4', pseudoId: 'c4', name: 'Hooli'),
        ),
      ),
      build: build,
      act: (bloc) => bloc.add(CompanyUserUpdate(withCompany)),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(CompanyUserStatus.success).having(
          (s) => s.companiesUsers.single,
          'companyUser',
          isA<CompanyUser>()
              .having((c) => c.type, 'type', PartyType.company)
              .having((c) => c.name, 'name', 'Hooli')
              .having((c) => c.partyId, 'partyId', 'C4')
              .having((c) => c.employees?.single.partyId, 'employee', 'U4'),
        ),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpdate_restThrowsDio_emitsFailureAndClearsList',
      setUp: () => when(
        () => restClient.createUser(user: newUser.getUser()!),
      ).thenThrow(dioError('Email already in use')),
      build: build,
      seed: () => CompanyUserState(
        status: CompanyUserStatus.success,
        companiesUsers: [companyUser1],
      ),
      act: (bloc) => bloc.add(CompanyUserUpdate(newUser)),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.failure,
          companiesUsers: [],
          message: 'Email already in use',
        ),
      ],
    );
  });

  group('CompanyUserDelete', () {
    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserDelete_user_keepsCompanyAndRemovesUser',
      setUp: () => when(
        () => restClient.deleteUser(partyId: 'U2', deleteCompanyToo: false),
      ).thenAnswer((_) async => user2),
      build: build,
      seed: () => CompanyUserState(
        status: CompanyUserStatus.success,
        companiesUsers: [companyUser1, companyUser2],
      ),
      act: (bloc) => bloc.add(CompanyUserDelete(user: user2)),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(
          CompanyUserStatus.success,
          companiesUsers: [companyUser1],
        ),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteUser(partyId: 'U2', deleteCompanyToo: false),
      ).thenThrow(dioError('User has orders')),
      build: build,
      seed: () => CompanyUserState(
        status: CompanyUserStatus.success,
        companiesUsers: [companyUser2],
      ),
      act: (bloc) => bloc.add(CompanyUserDelete(user: user2)),
      expect: () => [
        companyUserState(CompanyUserStatus.loading),
        companyUserState(CompanyUserStatus.failure, message: 'User has orders'),
      ],
    );
  });

  group('CompanyUserUpload', () {
    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpload_csv_importsDataRows',
      setUp: () => when(
        () => restClient.importCompanyUsers(any()),
      ).thenAnswer((_) async => ''),
      build: build,
      act: (bloc) => bloc.add(
        const CompanyUserUpload(
          'title\n'
          'id,type,name,role,email,url,tel,a1,a2,zip,city,prov,country,cid,comp\n'
          'p1,company,Acme,customer,a@b.c,,,Main 1,,1000,Town,,Thailand,THA,Acme\n'
          'too,short\n',
        ),
      ),
      expect: () => [
        companyUserState(CompanyUserStatus.filesLoading),
        companyUserState(
          CompanyUserStatus.success,
          message: 'compUserUploadSuccess',
        ),
      ],
      verify: (_) {
        final imported =
            verify(
                  () => restClient.importCompanyUsers(captureAny()),
                ).captured.single
                as List<CompanyUser>;
        expect(imported, hasLength(1));
        expect(imported.single.name, 'Acme');
        expect(imported.single.address?.city, 'Town');
      },
    );

    // https://github.com/growerp/growerp/issues/36
    // columns as written by get#ExportCompanyUsers
    const exportHeader =
        'Id,type,name,role,email,URL,telephone number,address1,address2,'
        'postalCode,city,province/state,country,countryId,companyId,companyName\n';

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpload_exportLayout_takesCompanyFromItsColumns',
      setUp: () => when(
        () => restClient.importCompanyUsers(any()),
      ).thenAnswer((_) async => ''),
      build: build,
      act: (bloc) => bloc.add(
        const CompanyUserUpload(
          'title\n'
          '$exportHeader'
          'p2,person,John Doe,customer,j@d.c,,,Main 1,,1000,Town,,Thailand,THA,C1,Acme\n',
        ),
      ),
      verify: (_) {
        final imported =
            verify(
                  () => restClient.importCompanyUsers(captureAny()),
                ).captured.single
                as List<CompanyUser>;
        expect(imported.single.address?.countryId, 'THA');
        expect(imported.single.company?.pseudoId, 'C1');
        expect(imported.single.company?.name, 'Acme');
      },
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserUpload_shortRow_isSkipped',
      setUp: () => when(
        () => restClient.importCompanyUsers(any()),
      ).thenAnswer((_) async => ''),
      build: build,
      act: (bloc) => bloc.add(
        const CompanyUserUpload(
          'title\n'
          '$exportHeader'
          'p3,person,Jane,customer,j@e.c,,,Main 2,,1000,Town,,Thailand\n',
        ),
      ),
      expect: () => [
        companyUserState(CompanyUserStatus.filesLoading),
        companyUserState(
          CompanyUserStatus.success,
          message: 'compUserUploadSuccess',
        ),
      ],
      verify: (_) =>
          verify(() => restClient.importCompanyUsers(const [])).called(1),
    );
  });

  group('CompanyUserDownload', () {
    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserDownload_scheduled_emitsSuccess',
      setUp: () => when(
        () => restClient.exportScreenCompanyUsers(),
      ).thenAnswer((_) async => ''),
      build: build,
      act: (bloc) => bloc.add(CompanyUserDownload()),
      expect: () => [
        companyUserState(CompanyUserStatus.filesLoading),
        companyUserState(
          CompanyUserStatus.success,
          message: 'compUserDownloadSuccess',
        ),
      ],
    );

    blocTest<CompanyUserBloc, CompanyUserState>(
      'CompanyUserDownload_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.exportScreenCompanyUsers(),
      ).thenThrow(dioError('No email server')),
      build: build,
      act: (bloc) => bloc.add(CompanyUserDownload()),
      expect: () => [
        companyUserState(CompanyUserStatus.filesLoading),
        companyUserState(CompanyUserStatus.failure, message: 'No email server'),
      ],
    );
  });
}

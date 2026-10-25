import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/mocks.dart';

const appId = 'AppAdmin';
// AuthLogin / AuthRegister / AuthLoggedOut are throttled 100ms.
const throttleWait = Duration(milliseconds: 150);

TypeMatcher<AuthState> authState(AuthStatus status, {String? message}) {
  var m = isA<AuthState>().having((s) => s.status, 'status', status);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockRestClient restClient;
  late MockWsClient chat;
  late MockWsClient notification;

  final user = User(userId: 'U1', partyId: 'P1', loginName: 'me@x.com');
  final company = Company(partyId: 'C1', name: 'Acme');
  final loggedIn = Authenticate(
    apiKey: 'key1',
    applicationId: appId,
    user: user,
    company: company,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    restClient = MockRestClient();
    chat = MockWsClient();
    notification = MockWsClient();
    for (final ws in [chat, notification]) {
      when(() => ws.connect(any(), any())).thenAnswer((_) async {});
      when(() => ws.close()).thenReturn(null);
    }
  });

  AuthBloc build() => AuthBloc(chat, notification, restClient, appId, company);

  void stubLogin(Authenticate result) => when(
    () => restClient.login(
      username: 'me@x.com',
      password: 'secret',
      applicationId: appId,
      timeZoneOffset: any(named: 'timeZoneOffset'),
      locale: 'en',
    ),
  ).thenAnswer((_) async => result);

  group('AuthLoad', () {
    blocTest<AuthBloc, AuthState>(
      'AuthLoad_noSavedSession_unauthenticatedWithDefaultCompany',
      setUp: () => when(
        () => restClient.getCompanies(searchString: 'C1', limit: 1),
      ).thenAnswer((_) async => Companies(companies: [company])),
      build: build,
      act: (bloc) => bloc.add(AuthLoad()),
      expect: () => [
        authState(AuthStatus.loading),
        authState(
          AuthStatus.unAuthenticated,
        ).having((s) => s.authenticate?.company, 'company', company),
      ],
      verify: (_) => verifyNever(() => chat.connect(any(), any())),
    );

    blocTest<AuthBloc, AuthState>(
      'AuthLoad_validSavedKey_authenticatesAndConnectsSockets',
      setUp: () async {
        await PersistFunctions.persistAuthenticate(loggedIn);
        when(
          () => restClient.getCompanies(searchString: 'C1', limit: 1),
        ).thenAnswer((_) async => Companies(companies: [company]));
        when(
          () => restClient.getAuthenticate(applicationId: appId),
        ).thenAnswer((_) async => loggedIn);
      },
      build: build,
      act: (bloc) => bloc.add(AuthLoad()),
      expect: () => [
        authState(AuthStatus.loading),
        authState(
          AuthStatus.authenticated,
        ).having((s) => s.authenticate?.apiKey, 'apiKey', 'key1'),
      ],
      verify: (_) {
        verify(() => chat.connect('key1', 'U1')).called(1);
        verify(() => notification.connect('key1', 'U1')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthLoad_savedKeyRejected_unauthenticated',
      setUp: () async {
        await PersistFunctions.persistAuthenticate(loggedIn);
        when(
          () => restClient.getCompanies(searchString: 'C1', limit: 1),
        ).thenAnswer((_) async => Companies(companies: [company]));
        when(
          () => restClient.getAuthenticate(applicationId: appId),
        ).thenAnswer((_) async => Authenticate());
      },
      build: build,
      act: (bloc) => bloc.add(AuthLoad()),
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.unAuthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthLoad_savedCompanyGone_unauthenticated',
      setUp: () async {
        await PersistFunctions.persistAuthenticate(loggedIn);
        when(
          () => restClient.getCompanies(searchString: 'C1', limit: 1),
        ).thenAnswer((_) async => Companies());
      },
      build: build,
      act: (bloc) => bloc.add(AuthLoad()),
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.unAuthenticated),
      ],
      verify: (_) => verifyNever(
        () => restClient.getAuthenticate(
          applicationId: any(named: 'applicationId'),
        ),
      ),
    );

    blocTest<AuthBloc, AuthState>(
      'AuthLoad_connectionError_failsButKeepsSavedSession',
      setUp: () async {
        await PersistFunctions.persistAuthenticate(loggedIn);
        when(
          () => restClient.getCompanies(searchString: 'C1', limit: 1),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
          ),
        );
      },
      build: build,
      act: (bloc) => bloc.add(AuthLoad()),
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.failure, message: 'Connection error'),
      ],
      verify: (_) async =>
          expect((await PersistFunctions.getAuthenticate())?.apiKey, 'key1'),
    );
  });

  group('AuthLogin', () {
    blocTest<AuthBloc, AuthState>(
      'AuthLogin_plainLogin_authenticatesConnectsAndPersistsKey',
      setUp: () => stubLogin(loggedIn),
      build: build,
      act: (bloc) => bloc.add(const AuthLogin('me@x.com', 'secret')),
      wait: throttleWait,
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.authenticated),
      ],
      verify: (_) async {
        verify(() => chat.connect('key1', 'U1')).called(1);
        verify(() => notification.connect('key1', 'U1')).called(1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('apiKey'), 'key1');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthLogin_setupRequired_staysUnauthenticatedWithoutSockets',
      setUp: () =>
          stubLogin(Authenticate(loginStatus: 'setupRequired', user: user)),
      build: build,
      act: (bloc) => bloc.add(const AuthLogin('me@x.com', 'secret')),
      wait: throttleWait,
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.unAuthenticated).having(
          (s) => s.authenticate?.loginStatus,
          'loginStatus',
          'setupRequired',
        ),
      ],
      verify: (_) {
        verifyNever(() => chat.connect(any(), any()));
        verifyNever(() => notification.connect(any(), any()));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthLogin_setupInProgress_connectsNotificationOnly',
      setUp: () => stubLogin(loggedIn.copyWith(loginStatus: 'setupInProgress')),
      build: build,
      act: (bloc) => bloc.add(const AuthLogin('me@x.com', 'secret')),
      wait: throttleWait,
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.unAuthenticated),
      ],
      verify: (_) {
        verify(() => notification.connect('key1', 'U1')).called(1);
        verifyNever(() => chat.connect(any(), any()));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthLogin_wrongPassword_emitsFailure',
      setUp: () => when(
        () => restClient.login(
          username: 'me@x.com',
          password: 'secret',
          applicationId: appId,
          timeZoneOffset: any(named: 'timeZoneOffset'),
          locale: 'en',
        ),
      ).thenThrow(dioError('Password incorrect for user me@x.com')),
      build: build,
      act: (bloc) => bloc.add(const AuthLogin('me@x.com', 'secret')),
      wait: throttleWait,
      expect: () => [
        authState(AuthStatus.loading),
        authState(
          AuthStatus.failure,
          message: 'Password incorrect for user me@x.com',
        ),
      ],
    );
  });

  group('AuthSetupCompleted', () {
    final inProgress = loggedIn.copyWith(loginStatus: 'setupInProgress');

    blocTest<AuthBloc, AuthState>(
      'AuthSetupCompleted_setupInProgress_promotesWithFreshStats',
      setUp: () => when(
        () => restClient.getAuthenticate(applicationId: appId),
      ).thenAnswer((_) async => loggedIn.copyWith(stats: Stats(leads: 7))),
      build: build,
      seed: () => AuthState(
        status: AuthStatus.unAuthenticated,
        authenticate: inProgress,
      ),
      act: (bloc) => bloc.add(const AuthSetupCompleted()),
      expect: () => [
        authState(AuthStatus.authenticated)
            .having((s) => s.authenticate?.loginStatus, 'loginStatus', isNull)
            .having((s) => s.authenticate?.stats?.leads, 'stats', 7),
      ],
      verify: (_) => verify(() => chat.connect('key1', 'U1')).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSetupCompleted_alreadyAuthenticated_doesNothing',
      build: build,
      seed: () =>
          AuthState(status: AuthStatus.authenticated, authenticate: loggedIn),
      act: (bloc) => bloc.add(const AuthSetupCompleted()),
      expect: () => <AuthState>[],
      verify: (_) => verifyNever(() => chat.connect(any(), any())),
    );
  });

  group('AuthRegister', () {
    final newAdmin = User(
      firstName: 'Max',
      lastName: 'Power',
      email: 'max@x.com',
      userGroup: UserGroup.admin,
      company: company,
    );

    void stubRegister(Future<Authenticate> Function(Invocation) answer) => when(
      () => restClient.register(
        applicationId: appId,
        email: 'max@x.com',
        companyPartyId: 'C1',
        firstName: 'Max',
        lastName: 'Power',
        userGroup: UserGroup.admin,
        newPassword: 'pw',
        timeZoneOffset: any(named: 'timeZoneOffset'),
        locale: 'en',
      ),
    ).thenAnswer(answer);

    blocTest<AuthBloc, AuthState>(
      'AuthRegister_success_persistsWithoutRegisteredSentinelKey',
      setUp: () => stubRegister(
        (_) async => Authenticate(apiKey: 'registered', user: newAdmin),
      ),
      build: build,
      act: (bloc) => bloc.add(
        AuthRegister(newAdmin, newPassword: 'pw', locale: const Locale('en')),
      ),
      wait: throttleWait,
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.unAuthenticated),
      ],
      verify: (_) async =>
          expect((await PersistFunctions.getAuthenticate())?.apiKey, isNull),
    );

    blocTest<AuthBloc, AuthState>(
      'AuthRegister_restThrowsDio_emitsFailure',
      setUp: () =>
          stubRegister((_) async => throw dioError('Email already in use')),
      build: build,
      act: (bloc) => bloc.add(
        AuthRegister(newAdmin, newPassword: 'pw', locale: const Locale('en')),
      ),
      wait: throttleWait,
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.failure, message: 'Email already in use'),
      ],
    );
  });

  group('AuthLoggedOut', () {
    blocTest<AuthBloc, AuthState>(
      'AuthLoggedOut_loggedIn_closesSocketsAndClearsKey',
      setUp: () =>
          when(() => restClient.logout()).thenAnswer((_) async => 'ok'),
      build: build,
      seed: () =>
          AuthState(status: AuthStatus.authenticated, authenticate: loggedIn),
      act: (bloc) => bloc.add(const AuthLoggedOut()),
      wait: throttleWait,
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.unAuthenticated, message: 'authLogoutSuccess'),
      ],
      verify: (_) async {
        verify(() => chat.close()).called(1);
        verify(() => notification.close()).called(1);
        // the bloc does not await these writes, and the removed and the
        // emptied key race: either way no key is left
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('apiKey'), anyOf(isNull, isEmpty));
        expect((await PersistFunctions.getAuthenticate())?.apiKey, isNull);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'AuthLoggedOut_restThrowsDio_emitsFailure',
      setUp: () => when(() => restClient.logout()).thenThrow(dioError('Nope')),
      build: build,
      seed: () =>
          AuthState(status: AuthStatus.authenticated, authenticate: loggedIn),
      act: (bloc) => bloc.add(const AuthLoggedOut()),
      wait: throttleWait,
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.failure, message: 'Nope'),
      ],
    );
  });

  group('AuthResetPassword', () {
    blocTest<AuthBloc, AuthState>(
      'AuthResetPassword_email_sendsAndReportsIt',
      setUp: () => when(
        () => restClient.resetPassword(username: 'me@x.com'),
      ).thenAnswer((_) async => 'ok'),
      build: build,
      act: (bloc) => bloc.add(const AuthResetPassword(username: 'me@x.com')),
      expect: () => [
        authState(AuthStatus.sendPassword),
        authState(
          AuthStatus.unAuthenticated,
          message: 'An email with password has been send to me@x.com',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthResetPassword_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.resetPassword(username: 'me@x.com'),
      ).thenThrow(dioError('Unknown user')),
      build: build,
      act: (bloc) => bloc.add(const AuthResetPassword(username: 'me@x.com')),
      expect: () => [
        authState(AuthStatus.sendPassword),
        authState(AuthStatus.failure, message: 'Unknown user'),
      ],
    );
  });

  group('AuthChangePassword', () {
    void stubUpdate(Future<Authenticate> Function(Invocation) answer) => when(
      () => restClient.updatePassword(
        username: 'me@x.com',
        oldPassword: 'old',
        newPassword: 'new',
        applicationId: appId,
      ),
    ).thenAnswer(answer);

    blocTest<AuthBloc, AuthState>(
      'AuthChangePassword_loggedIn_authenticatesWithNewKey',
      setUp: () => stubUpdate((_) async => loggedIn.copyWith(apiKey: 'key2')),
      build: build,
      seed: () =>
          AuthState(status: AuthStatus.authenticated, authenticate: loggedIn),
      act: (bloc) =>
          bloc.add(const AuthChangePassword('me@x.com', 'old', 'new')),
      expect: () => [
        authState(AuthStatus.loading),
        authState(
          AuthStatus.authenticated,
          message: 'passwordChangeSuccess:me@x.com',
        ).having((s) => s.authenticate?.apiKey, 'apiKey', 'key2'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthChangePassword_restThrowsDio_emitsFailure',
      setUp: () =>
          stubUpdate((_) async => throw dioError('Old password wrong')),
      build: build,
      seed: () =>
          AuthState(status: AuthStatus.authenticated, authenticate: loggedIn),
      act: (bloc) =>
          bloc.add(const AuthChangePassword('me@x.com', 'old', 'new')),
      expect: () => [
        authState(AuthStatus.loading),
        authState(AuthStatus.failure, message: 'Old password wrong'),
      ],
    );

    group(
      'forced password change',
      skip: 'https://github.com/growerp/growerp/issues/43',
      () {
        // login#User answers a required change with this sentinel session
        final passwordChange = Authenticate(
          apiKey: 'passwordChange',
          loginStatus: 'passwordChange',
          applicationId: appId,
          user: User(loginName: 'me@x.com'),
        );

        blocTest<AuthBloc, AuthState>(
          'AuthChangePassword_afterForcedChange_connectsSocketsWithNewKey',
          setUp: () =>
              stubUpdate((_) async => loggedIn.copyWith(apiKey: 'key2')),
          build: build,
          seed: () => AuthState(
            status: AuthStatus.unAuthenticated,
            authenticate: passwordChange,
          ),
          act: (bloc) =>
              bloc.add(const AuthChangePassword('me@x.com', 'old', 'new')),
          verify: (_) {
            verify(() => chat.connect('key2', 'U1')).called(1);
            verify(() => notification.connect('key2', 'U1')).called(1);
          },
        );
      },
    );
  });
}

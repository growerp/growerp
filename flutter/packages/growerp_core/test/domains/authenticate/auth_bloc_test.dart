import 'dart:convert'; // For jsonEncode
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/src/domains/authenticate/blocs/auth_bloc.dart';
import 'package:growerp_core/src/domains/authenticate/blocs/auth_event.dart';
import 'package:growerp_core/src/domains/authenticate/blocs/auth_state.dart';
import 'package:growerp_core/src/services/rest_client.dart';
import 'package:growerp_core/src/services/ws_client.dart';
import 'package:growerp_core/src/domains/common/functions/persist_functions.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For mock initial values
import 'package:flutter/foundation.dart'; // for kReleaseMode

// Mock classes
class MockRestClient extends Mock implements RestClient {}
class MockWsClient extends Mock implements WsClient {}

DioException _createDioException({RequestOptions? requestOptions, Response? response, DioExceptionType type = DioExceptionType.unknown, dynamic error, String? message}) {
  return DioException(
    requestOptions: requestOptions ?? RequestOptions(path: ''),
    response: response,
    type: type,
    error: error,
    message: message,
  );
}

void main() {
  group('AuthBloc Tests', () {
    late MockRestClient mockRestClient;
    late MockWsClient mockChatClient;
    late MockWsClient mockNotificationClient;
    late AuthBloc authBloc;
    late AuthState testInitialState;

    const String classificationId = 'AppAdmin';
    final Company company = Company(name: 'Default Company', partyId: 'defaultCompany', currency: Currency(description: 'US Dollar', currencyId: 'USD', symbol: '\$'));
    final Authenticate defaultAuth = Authenticate(classificationId: classificationId, company: company, status: AuthStatus.unAuthenticated);

    setUp(() {
      mockRestClient = MockRestClient();
      mockChatClient = MockWsClient();
      mockNotificationClient = MockWsClient();

      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      authBloc = AuthBloc(
        chatClient: mockChatClient,
        notificationClient: mockNotificationClient,
        restClient: mockRestClient,
        classificationId: classificationId,
        company: company,
      );
      testInitialState = authBloc.state;

      when(mockRestClient.getCompanies(searchString: company.name!, limit: 1))
          .thenAnswer((_) async => Companies(companies: [company]));
      when(mockChatClient.connect(any, any)).thenAnswer((_) async => {});
      when(mockNotificationClient.connect(any, any)).thenAnswer((_) async => {});
      when(mockChatClient.close()).thenAnswer((_) async {});
      when(mockNotificationClient.close()).thenAnswer((_) async {});
    });

    tearDown(() {
      authBloc.close();
    });

    group('AuthLoad Event Tests', () {
      final persistedUser = User(userId: 'persistedUser', firstName: 'Persisted', lastName: 'User', email: 'persisted@example.com', loginName: 'persistedUser');
      final persistedCompany = Company(name: 'Persisted Company', partyId: 'persistedComp', currency: Currency(description: 'Euro', currencyId: 'EUR', symbol: '€'));
      final persistedAuth = Authenticate(
        apiKey: 'validApiKey', user: persistedUser, company: persistedCompany,
        classificationId: classificationId, status: AuthStatus.authenticated,
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when AuthLoad is added and persisted data is valid',
        setUp: () async {
          SharedPreferences.setMockInitialValues({'authenticate': jsonEncode(persistedAuth.toJson())});
          authBloc = AuthBloc(
            chatClient: mockChatClient,notificationClient: mockNotificationClient,restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          when(mockRestClient.getCompanies(searchString: persistedCompany.name!, limit: 1))
              .thenAnswer((_) async => Companies(companies: [persistedCompany]));
          when(mockRestClient.getAuthenticate(classificationId: classificationId, apiKey: persistedAuth.apiKey))
              .thenAnswer((_) async => RestAuthenticate(authenticate: persistedAuth, message: 'Success'));
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoad()),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.authenticated, authenticate: persistedAuth, message: 'session renewed')
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unAuthenticated] when no persisted data',
        setUp: () {
           SharedPreferences.setMockInitialValues({});
           authBloc = AuthBloc(
            chatClient: mockChatClient,notificationClient: mockNotificationClient,restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          when(mockRestClient.getCompanies(searchString: company.name!, limit: 1))
              .thenAnswer((_) async => Companies(companies: [company]));
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoad()),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.unAuthenticated, authenticate: defaultAuth, message: 'data not found')
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unAuthenticated] when persisted company is no longer valid',
        setUp: () {
          final authWithInvalidCompany = Authenticate(
            apiKey: 'someKey',user: User(userId: 'testUser', email: 'test@example.com', loginName: 'testUser'),
            company: Company(name: 'Invalid Company', partyId: 'invalidComp'), classificationId: classificationId);
          SharedPreferences.setMockInitialValues({'authenticate': jsonEncode(authWithInvalidCompany.toJson())});
          authBloc = AuthBloc(
            chatClient: mockChatClient,notificationClient: mockNotificationClient,restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          when(mockRestClient.getCompanies(searchString: 'Invalid Company', limit: 1)).thenAnswer((_) async => Companies(companies: []));
          when(mockRestClient.getCompanies(searchString: company.name!, limit: 1)).thenAnswer((_) async => Companies(companies: [company]));
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoad()),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.unAuthenticated, authenticate: defaultAuth, message: 'Company Invalid Company not found, using ${company.name}.'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unAuthenticated] when persisted API key is invalid',
        setUp: () {
          SharedPreferences.setMockInitialValues({'authenticate': jsonEncode(persistedAuth.toJson())});
           authBloc = AuthBloc(
            chatClient: mockChatClient,notificationClient: mockNotificationClient,restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          when(mockRestClient.getCompanies(searchString: persistedCompany.name!, limit: 1))
              .thenAnswer((_) async => Companies(companies: [persistedCompany]));
          when(mockRestClient.getAuthenticate(classificationId: classificationId, apiKey: 'validApiKey'))
              .thenAnswer((_) async => RestAuthenticate(authenticate: persistedAuth.copyWith(apiKey: null), message: 'Invalid API Key'));
          when(mockRestClient.getCompanies(searchString: company.name!, limit: 1))
              .thenAnswer((_) async => Companies(companies: [company]));
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoad()),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.unAuthenticated, authenticate: defaultAuth, message: 'Login with key: validApiKey failed.'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] on DioException during getCompanies (initial check)',
        setUp: () {
           SharedPreferences.setMockInitialValues({});
           authBloc = AuthBloc(
            chatClient: mockChatClient,notificationClient: mockNotificationClient,restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;
          final dioException = _createDioException(error: 'Network error');
          when(mockRestClient.getCompanies(searchString: company.name!, limit: 1)).thenThrow(dioException);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoad()),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.failure, authenticate: defaultAuth, message: dioException.toString()),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] on DioException during getAuthenticate (API key check)',
        setUp: () {
          SharedPreferences.setMockInitialValues({'authenticate': jsonEncode(persistedAuth.toJson())});
           authBloc = AuthBloc(
            chatClient: mockChatClient,notificationClient: mockNotificationClient,restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          final dioException = _createDioException(error: 'API error');
          when(mockRestClient.getCompanies(searchString: persistedCompany.name!, limit: 1))
              .thenAnswer((_) async => Companies(companies: [persistedCompany]));
          when(mockRestClient.getAuthenticate(classificationId: classificationId, apiKey: 'validApiKey')).thenThrow(dioException);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoad()),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.failure, message: dioException.toString()),
        ],
      );
    });

    group('AuthRegister Event Tests', () {
      final newUser = User(email: 'newuser@example.com', firstName: 'New', lastName: 'User', company: company);
      final registeredAuthResponse = Authenticate(
          classificationId: classificationId, company: company,
          user: newUser.copyWith(password: null), message: 'Registration successful for newuser@example.com');

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unAuthenticated] with success message on successful AuthRegister',
        setUp: () {
          SharedPreferences.setMockInitialValues({});
          authBloc = AuthBloc(
            chatClient: mockChatClient,notificationClient: mockNotificationClient,restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          when(mockRestClient.register(
            classificationId: classificationId, email: newUser.email!, companyPartyId: newUser.company?.partyId,
            firstName: newUser.firstName!, lastName: newUser.lastName!,
            newPassword: newUser.password ?? (kReleaseMode ? '' : 'qqqqqq9!'),
          )).thenAnswer((_) async => registeredAuthResponse);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthRegister(user: newUser.copyWith(password: 'newPassword123'))),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(
              status: AuthStatus.unAuthenticated,
              authenticate: registeredAuthResponse.copyWith(message: 'Registration successful for newuser@example.com\nYou can now login with the password sent by email'),
              message: 'Registration successful for newuser@example.com\nYou can now login with the password sent by email'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] on AuthRegister when RestClient throws DioException',
        setUp: () {
          SharedPreferences.setMockInitialValues({});
          authBloc = AuthBloc(
            chatClient: mockChatClient,notificationClient: mockNotificationClient,restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          final dioException = _createDioException(message: 'Registration failed', error: 'Network Error');
          when(mockRestClient.register(
            classificationId: classificationId, email: newUser.email!, companyPartyId: newUser.company?.partyId,
            firstName: newUser.firstName!, lastName: newUser.lastName!,
            newPassword: newUser.password ?? (kReleaseMode ? '' : 'qqqqqq9!'),
          )).thenThrow(dioException);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthRegister(user: newUser.copyWith(password: 'newPassword123'))),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.failure, authenticate: defaultAuth, message: dioException.toString()),
        ],
      );
    });

    group('AuthLoggedOut Event Tests', () {
      final authenticatedUser = User(userId: 'loggedOutUser', email: 'logout@mail.com', loginName: 'loggedOutUser');
      final authToLogout = Authenticate(
            apiKey: 'toBeLoggedOutApiKey', user: authenticatedUser, company: company,
            classificationId: classificationId, status: AuthStatus.authenticated);

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unAuthenticated] with message on successful AuthLoggedOut',
        setUp: () {
          SharedPreferences.setMockInitialValues({'authenticate': jsonEncode(authToLogout.toJson())});
          authBloc = AuthBloc(
            chatClient: mockChatClient, notificationClient: mockNotificationClient, restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          when(mockRestClient.logout(authToLogout.apiKey!)).thenAnswer((_) async {});
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoggedOut()),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.unAuthenticated, authenticate: defaultAuth, message: "Logged off"),
        ],
        verify: (_) {
          verify(mockRestClient.logout(authToLogout.apiKey!)).called(1);
          verify(mockChatClient.close()).called(1);
          verify(mockNotificationClient.close()).called(1);
        }
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] on AuthLoggedOut when RestClient throws DioException',
        setUp: () {
           SharedPreferences.setMockInitialValues({'authenticate': jsonEncode(authToLogout.toJson())});
          authBloc = AuthBloc(
            chatClient: mockChatClient, notificationClient: mockNotificationClient, restClient: mockRestClient,
            classificationId: classificationId, company: company);
          testInitialState = authBloc.state;

          final dioException = _createDioException(message: 'Logout failed');
          when(mockRestClient.logout(authToLogout.apiKey!)).thenThrow(dioException);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthLoggedOut()),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading),
          testInitialState.copyWith(status: AuthStatus.failure, message: dioException.toString()),
        ],
        verify: (_) {
          verify(mockRestClient.logout(authToLogout.apiKey!)).called(1);
          verify(mockChatClient.close()).called(1);
          verify(mockNotificationClient.close()).called(1);
        }
      );
    });

    group('AuthLogin Event Tests', () {
      const String username = 'testuser';
      const String password = 'password';
      final loginUser = User(userId: 'testUser', loginName: username, email: 'testuser@example.com');
      final loggedInAuth = Authenticate(
          apiKey: 'validApiKey', user: loginUser, company: company,
          classificationId: classificationId, status: AuthStatus.authenticated);

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] on successful AuthLogin',
        setUp: () {
          SharedPreferences.setMockInitialValues({});
          authBloc = AuthBloc(mockChatClient, mockNotificationClient, mockRestClient, classificationId, company);
          testInitialState = authBloc.state;

          when(mockRestClient.login(
            username: username, password: password, classificationId: classificationId,
            extraInfo: anyNamed('extraInfo'), companyName: anyNamed('companyName'),
            currencyId: anyNamed('currencyId'), demoData: anyNamed('demoData'),
          )).thenAnswer((_) async => loggedInAuth);
          when(mockChatClient.connect(loggedInAuth.apiKey!, loginUser.userId!)).thenAnswer((_) async => {});
          when(mockNotificationClient.connect(loggedInAuth.apiKey!, loginUser.userId!)).thenAnswer((_) async => {});
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthLogin(username: username, password: password)),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading, authenticate: defaultAuth.copyWith(status: AuthStatus.loading, message: null)),
          testInitialState.copyWith(
              status: AuthStatus.authenticated,
              authenticate: loggedInAuth.copyWith(message: 'You are logged in now...'),
              message: 'You are logged in now...'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unAuthenticated] with failure message when apiKey is null (login failed)',
        setUp: () {
          SharedPreferences.setMockInitialValues({});
          authBloc = AuthBloc(mockChatClient, mockNotificationClient, mockRestClient, classificationId, company);
          testInitialState = authBloc.state;

          final failedLoginAuth = Authenticate(apiKey: null, user: loginUser, company: company, classificationId: classificationId, message: "Login failed");
          when(mockRestClient.login(
            username: username, password: password, classificationId: classificationId,
            extraInfo: anyNamed('extraInfo'), companyName: anyNamed('companyName'),
            currencyId: anyNamed('currencyId'), demoData: anyNamed('demoData'),
          )).thenAnswer((_) async => failedLoginAuth);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthLogin(username: username, password: password)),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading, authenticate: defaultAuth.copyWith(status: AuthStatus.loading, message: null)),
          testInitialState.copyWith(
            status: AuthStatus.unAuthenticated,
            authenticate: defaultAuth.copyWith(message: "Login failed: User ID/Password not valid"),
            message: "Login failed: User ID/Password not valid"),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unAuthenticated] with moreInfo apiKey when login requires more info',
        setUp: () {
          SharedPreferences.setMockInitialValues({});
          authBloc = AuthBloc(mockChatClient, mockNotificationClient, mockRestClient, classificationId, company);
          testInitialState = authBloc.state;

          final moreInfoAuth = Authenticate(apiKey: 'moreInfo', user: loginUser, company: company, classificationId: classificationId);
          when(mockRestClient.login(
            username: username, password: password, classificationId: classificationId,
            extraInfo: anyNamed('extraInfo'), companyName: anyNamed('companyName'),
            currencyId: anyNamed('currencyId'), demoData: anyNamed('demoData'),
          )).thenAnswer((_) async => moreInfoAuth);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthLogin(username: username, password: password)),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading, authenticate: defaultAuth.copyWith(status: AuthStatus.loading, message: null)),
          testInitialState.copyWith(status: AuthStatus.unAuthenticated, authenticate: moreInfoAuth),
        ],
      );

       blocTest<AuthBloc, AuthState>(
        'emits [loading, unAuthenticated] with passwordChange apiKey when login requires password change',
        setUp: () {
          SharedPreferences.setMockInitialValues({});
          authBloc = AuthBloc(mockChatClient, mockNotificationClient, mockRestClient, classificationId, company);
          testInitialState = authBloc.state;

          final passwordChangeAuth = Authenticate(apiKey: 'passwordChange', user: loginUser, company: company, classificationId: classificationId);
          when(mockRestClient.login(
            username: username, password: password, classificationId: classificationId,
            extraInfo: anyNamed('extraInfo'), companyName: anyNamed('companyName'),
            currencyId: anyNamed('currencyId'), demoData: anyNamed('demoData'),
          )).thenAnswer((_) async => passwordChangeAuth);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthLogin(username: username, password: password)),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading, authenticate: defaultAuth.copyWith(status: AuthStatus.loading, message: null)),
          testInitialState.copyWith(status: AuthStatus.unAuthenticated, authenticate: passwordChangeAuth),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] on DioException during login',
        setUp: () {
          SharedPreferences.setMockInitialValues({});
          authBloc = AuthBloc(mockChatClient, mockNotificationClient, mockRestClient, classificationId, company);
          testInitialState = authBloc.state;

          final dioException = _createDioException(message: "Connection error");
          when(mockRestClient.login(
            username: username, password: password, classificationId: classificationId,
            extraInfo: anyNamed('extraInfo'), companyName: anyNamed('companyName'),
            currencyId: anyNamed('currencyId'), demoData: anyNamed('demoData'),
          )).thenThrow(dioException);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthLogin(username: username, password: password)),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading, authenticate: defaultAuth.copyWith(status: AuthStatus.loading, message: null)),
          testInitialState.copyWith(status: AuthStatus.failure, authenticate: defaultAuth.copyWith(message: dioException.toString()), message: dioException.toString()),
        ],
      );
    });

    group('AuthResetPassword Event Tests', () {
      const String resetUsername = 'resetuser@example.com';

      blocTest<AuthBloc, AuthState>(
        'emits [sendPassword, unAuthenticated] with success message on successful AuthResetPassword',
        setUp: () {
          when(mockRestClient.resetPassword(username: resetUsername))
              .thenAnswer((_) async {});
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(AuthResetPassword(username: resetUsername)),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.sendPassword, authenticate: defaultAuth.copyWith(status: AuthStatus.sendPassword, message: null)),
          testInitialState.copyWith(
              status: AuthStatus.unAuthenticated,
              authenticate: defaultAuth.copyWith(message: 'An email with password has been send to $resetUsername'),
              message: 'An email with password has been send to $resetUsername'),
        ],
        verify: (_) {
          verify(mockRestClient.resetPassword(username: resetUsername)).called(1);
        }
      );

      blocTest<AuthBloc, AuthState>(
        'emits [sendPassword, failure] on AuthResetPassword when RestClient throws DioException',
        setUp: () {
          final dioException = _createDioException(message: 'Reset failed');
          when(mockRestClient.resetPassword(username: resetUsername))
              .thenThrow(dioException);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthResetPassword(username: resetUsername)),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.sendPassword, authenticate: defaultAuth.copyWith(status: AuthStatus.sendPassword, message: null)),
          testInitialState.copyWith(
            status: AuthStatus.failure,
            authenticate: defaultAuth.copyWith(message: _createDioException(message: 'Reset failed').toString()),
            message: _createDioException(message: 'Reset failed').toString()),
        ],
        verify: (_) {
          verify(mockRestClient.resetPassword(username: resetUsername)).called(1);
        }
      );
    });

    group('AuthChangePassword Event Tests', () {
      const String changePwUsername = 'testuser@example.com';
      const String oldPassword = 'oldPassword123';
      const String newPassword = 'newPassword456';
      final initialUser = User(userId: 'user123', email: changePwUsername, loginName: changePwUsername);
      final initialAuthForChange = Authenticate(
          apiKey: 'currentApiKey', user: initialUser, company: company,
          classificationId: classificationId, status: AuthStatus.authenticated);
      // The BLoC actually uses the old apiKey for the updatePassword call, then gets a new one.
      // For simplicity, let's assume updatePassword call itself doesn't return a new apiKey,
      // but a new Authenticate object (which might have a new session/apiKey).
      // The current BLoC implementation reuses the existing apiKey if the call to updatePassword
      // doesn't return a new one in its Authenticate object. Let's assume it does return a new one.
      final updatedAuthOnChange = initialAuthForChange.copyWith(apiKey: 'newApiKeyAfterPasswordChange');

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] with new apiKey on successful AuthChangePassword',
        setUp: () {
          SharedPreferences.setMockInitialValues({
            'authenticate': jsonEncode(initialAuthForChange.toJson()),
            'apiKey': initialAuthForChange.apiKey! // Persist old API key as well if BLoC uses it
          });
          authBloc = AuthBloc(mockChatClient, mockNotificationClient, mockRestClient, classificationId, company);
          testInitialState = authBloc.state; // This state will be authenticated with initialAuthForChange

          when(mockRestClient.updatePassword(
            username: changePwUsername, oldPassword: oldPassword, newPassword: newPassword,
            classificationId: classificationId, apiKey: initialAuthForChange.apiKey! // BLoC sends current API key
          )).thenAnswer((_) async => updatedAuthOnChange); // Server returns new auth details

          when(mockChatClient.connect(updatedAuthOnChange.apiKey!, updatedAuthOnChange.user!.userId!))
              .thenAnswer((_) async => {});
          when(mockNotificationClient.connect(updatedAuthOnChange.apiKey!, updatedAuthOnChange.user!.userId!))
              .thenAnswer((_) async => {});
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthChangePassword(
            username: changePwUsername, oldPassword: oldPassword, newPassword: newPassword)),
        expect: () => [
          // Starts with the authenticated state from setUp
          testInitialState.copyWith(status: AuthStatus.loading, message: null),
          AuthState( // Explicitly define the final state
              status: AuthStatus.authenticated,
              authenticate: updatedAuthOnChange.copyWith(message: 'password successfully changed for user: $changePwUsername'),
              message: 'password successfully changed for user: $changePwUsername'),
        ],
        verify: (_) {
          verify(mockRestClient.updatePassword(
              username: changePwUsername, oldPassword: oldPassword, newPassword: newPassword,
              classificationId: classificationId, apiKey: initialAuthForChange.apiKey!)).called(1);
          verify(mockChatClient.connect(updatedAuthOnChange.apiKey!, updatedAuthOnChange.user!.userId!)).called(1);
          verify(mockNotificationClient.connect(updatedAuthOnChange.apiKey!, updatedAuthOnChange.user!.userId!)).called(1);
        }
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] on AuthChangePassword when RestClient throws DioException',
        setUp: () {
          SharedPreferences.setMockInitialValues({
            'authenticate': jsonEncode(initialAuthForChange.toJson()),
            'apiKey': initialAuthForChange.apiKey!
          });
          authBloc = AuthBloc(mockChatClient, mockNotificationClient, mockRestClient, classificationId, company);
          testInitialState = authBloc.state; // Authenticated state

          final dioException = _createDioException(message: 'Password change failed');
          when(mockRestClient.updatePassword(
            username: changePwUsername, oldPassword: oldPassword, newPassword: newPassword,
            classificationId: classificationId, apiKey: initialAuthForChange.apiKey!
          )).thenThrow(dioException);
        },
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthChangePassword(
            username: changePwUsername, oldPassword: oldPassword, newPassword: newPassword)),
        expect: () => [
          testInitialState.copyWith(status: AuthStatus.loading, message: null),
          testInitialState.copyWith(
              status: AuthStatus.failure,
              message: dioException.toString()), // Authenticate object remains initialAuthForChange
        ],
        verify: (_) {
          verify(mockRestClient.updatePassword(
              username: changePwUsername, oldPassword: oldPassword, newPassword: newPassword,
              classificationId: classificationId, apiKey: initialAuthForChange.apiKey!)).called(1);
          // WS connect should not be called on failure
          verifyNever(mockChatClient.connect(any, any));
          verifyNever(mockNotificationClient.connect(any, any));
        }
      );
    });

  });
}

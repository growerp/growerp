/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:backend/@backend.dart';
import '../testdata.dart';

class MockReposRepository extends Mock implements Moqui {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockReposRepository mockReposRepository;
  MockAuthBloc? authBloc;

  setUp(() {
    mockReposRepository = MockReposRepository();
    authBloc = MockAuthBloc();
  });

  tearDown(() {
    authBloc?.close();
  });

  group('Login bloc test', () {
    blocTest(
      'check initial state',
      build: () => LoginBloc(repos: mockReposRepository),
      expect: () => <AuthState>[],
    );

    blocTest('Login success',
        build: () => LoginBloc(repos: mockReposRepository),
        act: (dynamic bloc) async {
          when(mockReposRepository.login(
                  username: emailAddress, password: password))
              .thenAnswer((_) async => authenticate);
          bloc.add(LoginButtonPressed(
              company: company, username: emailAddress, password: password));
          whenListen(
              authBloc!,
              Stream.fromIterable(
                  <AuthEvent>[LoggedIn(authenticate: authenticate)]));
        },
        expect: () => <LoginState>[LogginInProgress(), LoginOk(authenticate)]);

    blocTest(
      'Login failure',
      build: () => LoginBloc(repos: mockReposRepository),
      act: (dynamic bloc) async {
        when(mockReposRepository.login(username: username, password: password))
            .thenAnswer((_) async => errorMessage);
        bloc.add(LoginButtonPressed(
            company: company, username: username, password: password));
      },
      expect: () => <LoginState>[LogginInProgress(), LoginError(errorMessage)],
    );

    blocTest(
      'Login succes and change password',
      build: () => LoginBloc(repos: mockReposRepository),
      act: (dynamic bloc) async {
        when(mockReposRepository.login(username: username, password: password))
            .thenAnswer((_) async => "passwordChange");
        bloc.add(LoginButtonPressed(
            company: company, username: username, password: password));
        whenListen(
            authBloc!,
            Stream.fromIterable(
                <AuthEvent>[LoggedIn(authenticate: authenticate)]));
      },
      expect: () => <LoginState>[
        LogginInProgress(),
        LoginChangePw(company, username, password),
      ],
    );
  });
}

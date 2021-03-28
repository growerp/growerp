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

void main() {
  AuthBloc authBloc;
  late MockReposRepository mockReposRepository;

  setUp(() {
    mockReposRepository = MockReposRepository();
  });

  group('Authbloc test>>>', () {
    blocTest('check initial state',
        build: () => AuthBloc(mockReposRepository), expect: () => []);

    blocTest(
      'succesful connection and Unauthenticated',
      build: () => AuthBloc(mockReposRepository),
      act: (dynamic bloc) async {
        when(mockReposRepository.getConnected()).thenAnswer((_) async => true);
        when(mockReposRepository.getAuthenticate())
            .thenAnswer((_) async => authenticateNoKey);
        bloc..add(LoadAuth());
      },
      expect: () => <AuthState>[
        AuthLoading(),
        AuthUnauthenticated(authenticateNoKey),
      ],
    );
    blocTest(
      'failed connection with ConnectionProblem',
      build: () => AuthBloc(mockReposRepository),
      act: (dynamic bloc) async {
        when(mockReposRepository.getConnected())
            .thenAnswer((_) async => errorMessage);
        bloc.add(LoadAuth());
      },
      expect: () => <AuthState>[
        AuthLoading(),
        AuthProblem(errorMessage),
      ],
    );

    blocTest(
      '???succesfull connection and Authenticated',
      build: () => AuthBloc(mockReposRepository),
      act: (dynamic bloc) async {
        when(mockReposRepository.getConnected()).thenAnswer((_) async => true);
        when(mockReposRepository.getAuthenticate())
            .thenAnswer((_) async => authenticate);
        when(mockReposRepository.checkApikey()).thenAnswer((_) async => true);
        bloc.add(LoadAuth());
      },
      expect: () => <AuthState>[
        AuthLoading(),
        AuthAuthenticated(authenticate),
      ],
    );
    blocTest(
      'connection and login and logout',
      build: () => AuthBloc(mockReposRepository),
      act: (dynamic bloc) async {
        when(mockReposRepository.getConnected()).thenAnswer((_) async => true);
        when(mockReposRepository.getAuthenticate())
            .thenAnswer((_) async => authenticateNoKey);
        when(mockReposRepository.logout())
            .thenAnswer((_) async => authenticateNoKey);
        bloc.add(LoadAuth());
        bloc.add(LoggedIn(authenticate: authenticate));
        bloc.add(Logout());
      },
      expect: () => <AuthState>[
        AuthLoading(),
        AuthUnauthenticated(authenticateNoKey),
        AuthLoading(),
        AuthAuthenticated(authenticate),
        AuthLoading(),
        AuthUnauthenticated(authenticateNoKey, 'you are logged out now'),
      ],
    );
    blocTest(
      'succesful connection and register',
      build: () => AuthBloc(mockReposRepository),
      act: (dynamic bloc) async {
        when(mockReposRepository.getConnected()).thenAnswer((_) async => true);
        when(mockReposRepository.getAuthenticate())
            .thenAnswer((_) async => authenticateNoKey);
        bloc.add(LoadAuth());
        bloc.add(LoggedIn(authenticate: authenticate));
      },
      expect: () => <AuthState>[
        AuthLoading(),
        AuthUnauthenticated(authenticateNoKey),
        AuthLoading(),
        AuthAuthenticated(authenticate),
      ],
    );

    blocTest(
      'succesful connection login screen and reset password',
      build: () => AuthBloc(mockReposRepository),
      act: (dynamic bloc) async {
        when(mockReposRepository.getConnected()).thenAnswer((_) async => true);
        when(mockReposRepository.getAuthenticate())
            .thenAnswer((_) async => authenticateNoKey);
        when(mockReposRepository.resetPassword(username: 'dummyEmail'))
            .thenAnswer((_) async => true);
        bloc.add(LoadAuth());
        await bloc.add(ResetPassword(username: 'dummyEmail'));
      },
      expect: () => <AuthState>[
        AuthLoading(),
        AuthUnauthenticated(authenticateNoKey),
      ],
    );
  });
}

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

import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:moqui/moqui.dart';
import 'package:testdata/testdata.dart';

class MockReposRepository extends Mock implements Moqui {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MockReposRepository mockReposRepository;

  setUp(() {
    mockReposRepository = MockReposRepository();
  });

  group('ChangePassword bloc test', () {
    blocTest('check initial state',
        build: () => ChangePwBloc(repos: mockReposRepository),
        expect: <AuthState>[]);

    blocTest('ChangePw success',
        build: () => ChangePwBloc(repos: mockReposRepository),
        act: (bloc) async {
          when(mockReposRepository.updatePassword(
                  username: username,
                  oldPassword: password,
                  newPassword: password))
              .thenAnswer((_) async => authenticateNoKey);
          bloc.add(ChangePwButtonPressed(
              username: username,
              oldPassword: password,
              newPassword: password));
        },
        expect: <ChangePwState>[ChangePwInProgress(), ChangePwOk()]);
// cannot run see: https://stackoverflow.com/questions/57689492/flutter-unhandled-exception-servicesbinding-defaultbinarymessenger-was-accesse
/*    blocTest('ChangePw failure',
        build: () =>
            ChangePwBloc(authBloc: mockAuthBloc, repos: mockReposRepository),
        act: (bloc) async {
          when(mockReposRepository.updatePassword(
                  username: username,
                  oldPassword: password,
                  newPassword: password))
              .thenAnswer((_) async => errorMessage);
          bloc.add(ChangePwButtonPressed(
              username: username, oldPassword: password, newPassword: password));
          whenListen(mockAuthBloc, Stream.fromIterable(<AuthEvent>[Login()]));
        },
      expect: <ChangePwState>[
        ChangePwInProgress(),
        ChangePwFailure(message: errorMessage)
      ],
    );
*/
  });
}

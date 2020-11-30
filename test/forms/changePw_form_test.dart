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
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ecommerce/blocs/@blocs.dart';
import 'package:ecommerce/services/@services.dart';
import 'package:ecommerce/forms/@forms.dart';
import '../data.dart';

class MockRepos extends Mock implements Moqui {}

class MockAuthBloc extends MockBloc<AuthState> implements AuthBloc {}

class MockChangePwBloc extends MockBloc<ChangePwState> implements ChangePwBloc {
}

void main() {
  group('ChangePw_Form test: ', () {
    Object repos;
    ChangePwBloc changePwBloc;
    AuthBloc authBloc;

    setUp(() {
      repos = MockRepos();
      authBloc = MockAuthBloc();
      changePwBloc = MockChangePwBloc();
    });

    tearDown(() {
      changePwBloc.close();
      authBloc.close();
    });

    testWidgets('check text fields + Load changePw event',
        (WidgetTester tester) async {
      await tester.pumpWidget(RepositoryProvider(
          create: (context) => repos,
          child: MaterialApp(
              home: Scaffold(
            body: ChangePwForm(changePwArgs: ChangePwArgs(username, password)),
          ))));
      await tester.pumpAndSettle();
      expect(find.text('You entered the correct temporary password\n'),
          findsOneWidget);
      await tester.enterText(find.byKey(Key('password1')), newPassword);
      await tester.enterText(find.byKey(Key('password2')), newPassword);
      await tester
          .tap(find.widgetWithText(RaisedButton, 'Submit new Password'));
      await tester.pumpAndSettle();
      whenListen(
          changePwBloc,
          Stream.fromIterable(<ChangePwEvent>[
            ChangePwButtonPressed(
                username: username,
                oldPassword: password,
                newPassword: newPassword)
          ]));
    });
  });
}

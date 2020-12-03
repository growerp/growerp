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
import 'package:core/blocs/@blocs.dart';
import 'package:moqui/moqui.dart';
import 'package:core/forms/@forms.dart';
import 'package:core/router.dart' as router;
import '../data.dart';

class MockRepos extends Mock implements Moqui {}

class MockAuthBloc extends MockBloc<AuthState> implements AuthBloc {}

class MockRegisterBloc extends MockBloc<RegisterState> implements RegisterBloc {
}

void main() {
  group('Register_Form', () {
    Object repos;
    RegisterBloc registerBloc;
    AuthBloc authBloc;

    setUp(() {
      repos = MockRepos();
      authBloc = MockAuthBloc();
      registerBloc = MockRegisterBloc();
    });

    tearDown(() {
      registerBloc.close();
      authBloc.close();
    });

    testWidgets('check form text fields + Load register event',
        (WidgetTester tester) async {
      when(authBloc.state).thenReturn(AuthUnauthenticated(null));
      when(registerBloc.state).thenReturn(RegisterLoaded());
      await tester.pumpWidget(RepositoryProvider(
        create: (context) => repos,
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            onGenerateRoute: router.generateRoute,
            home: Scaffold(
              body: RegisterForm(),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Register a new company and admin'), findsWidgets);
      expect(find.byKey(Key('firstName')), findsOneWidget);
      expect(find.byKey(Key('lastName')), findsOneWidget);
      expect(find.byKey(Key('dropDownCur')), findsOneWidget);
      expect(find.byKey(Key('dropDownClass')), findsOneWidget);
      expect(find.byKey(Key('companyName')), findsOneWidget);
      expect(find.text('A temporary password will be send by email'),
          findsOneWidget);
      expect(find.byKey(Key('email')), findsOneWidget);
      expect(find.text('Currency'), findsWidgets);
      expect(find.byKey(Key('newCompany')), findsOneWidget);
    });

    testWidgets('RegisterForm enter fields and press register',
        (WidgetTester tester) async {
      when(authBloc.state).thenReturn(AuthUnauthenticated(null));
      when(registerBloc.state).thenReturn(RegisterLoaded());
      await tester.pumpWidget(RepositoryProvider(
        create: (context) => repos,
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            onGenerateRoute: router.generateRoute,
            home: Scaffold(
              body: RegisterForm(),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key('companyName')), companyName);
//      await tester.enterText(find.byType(DropdownButton), currencies[2]);
      await tester.enterText(find.byKey(Key('firstName')), username);
      await tester.enterText(find.byKey(Key('lastName')), password);
      await tester.enterText(find.byKey(Key('email')), emailAddress);
      await tester.tap(find.byKey(Key('newCompany')));
      await tester.pumpAndSettle();
      whenListen(
          registerBloc,
          Stream.fromIterable(<RegisterEvent>[
            LoadRegister(),
            RegisterCompanyAdmin(
                classificationId: classificationId,
                companyName: companyName,
                currencyId: currencyId,
                firstName: firstName,
                lastName: lastName,
                email: emailAddress)
          ]));
    });
  });
}
